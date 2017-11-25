#!/bin/bash
set -e 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CSV=$1
NAME=$2
DATAPATH=$3
PROGRAM=$4

# Check that we have afl-showmap in $PATH.
hash afl-showmap 2>/dev/null || { echo >&2 "I require afl-showmap but it's not installed.  Aborting."; exit 1; }
#command -v afl-showmap >/dev/null 2>&1 || { echo >&2 "I require afl-showmap but it's not installed.  Aborting."; exit 1; }

echo "Generating ground truth data"
# Start from some CSV input and make a JSON ground truth.
$DIR/analyze_groundtruth $NAME $CSV $DIR/$NAME'-groundtruth.json' $DATAPATH

echo "Generating vector extraction commands"
# Generate vector extract commands from the JSON.
mkdir -p $DIR/$NAME'-vectors'
$DIR/mk_command "$DIR/get_afl_vec \"$PROGRAM\"" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-vectors' > $DIR/$NAME'-commands'

echo "Extracting vectors"
# Run the vector extract commands through GNU parallel. 
parallel --bar < $DIR/$NAME'-commands'

# Run clustering on the extracted vectors. 
echo "Running KMeans clustering"
$DIR/cluster --cluster-method=kmeans --clusters=25 --outfile=$DIR/$NAME'-kmeans.json' --name=kmeans --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running KMeans(PCA) clustering"
$DIR/cluster --pca=0.95 --cluster-method=kmeans --clusters=25 --outfile=$DIR/$NAME'-kmeans-pca.json' --name=kmeans-pca --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running DBSCAN clustering"
$DIR/cluster --cluster-method=dbscan --outfile=$DIR/$NAME'-dbscan.json' --name=dbscan --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running Aggregate clustering"
$DIR/cluster --cluster-method=agg --clusters=25 --outfile=$DIR/$NAME'-agg.json' --name=agg --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running Aggregate(PCA) clustering"
$DIR/cluster --pca=0.95 --cluster-method=agg --clusters=25 --outfile=$DIR/$NAME'-agg-pca.json' --name=agg-pca --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running MeanShift clustering"
$DIR/cluster --cluster-method=meanshift --outfile=$DIR/$NAME'-meanshift.json' --name=meanshift --variance-threshold=0.9 $DIR/$NAME'-vectors'

echo "Running MeanShift(PCA) clustering"
$DIR/cluster --pca=0.95 --cluster-method=meanshift --outfile=$DIR/$NAME'-meanshift-pca.json' --name=meanshift-pca --variance-threshold=0.9 $DIR/$NAME'-vectors'

# Compare the produced cluster(s) with ground truth and report. 
echo "Comparing clusters using FMI"
$DIR/analyze_clusters $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans.json'
$DIR/analyze_clusters $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans-pca.json'
$DIR/analyze_clusters $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-dbscan.json'
$DIR/analyze_clusters $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg.json'
$DIR/analyze_clusters $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg-pca.json'
$DIR/analyze_clusters $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift.json'
$DIR/analyze_clusters $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift-pca.json'

echo "Comparing clusters using F"
$DIR/analyze_clusters --method="f" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans.json'
$DIR/analyze_clusters --method="f" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans-pca.json'
$DIR/analyze_clusters --method="f" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-dbscan.json'
$DIR/analyze_clusters --method="f" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg.json'
$DIR/analyze_clusters --method="f" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg-pca.json'
$DIR/analyze_clusters --method="f" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift.json'
$DIR/analyze_clusters --method="f" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift-pca.json'

echo "Comparing clusters using ARI"
$DIR/analyze_clusters --method="ari" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans.json'
$DIR/analyze_clusters --method="ari" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans-pca.json'
$DIR/analyze_clusters --method="ari" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-dbscan.json'
$DIR/analyze_clusters --method="ari" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg.json'
$DIR/analyze_clusters --method="ari" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg-pca.json'
$DIR/analyze_clusters --method="ari" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift.json'
$DIR/analyze_clusters --method="ari" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift-pca.json'

echo "Comparing clusters using AMI"
$DIR/analyze_clusters --method="ami" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans.json'
$DIR/analyze_clusters --method="ami" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-kmeans-pca.json'
$DIR/analyze_clusters --method="ami" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-dbscan.json'
$DIR/analyze_clusters --method="ami" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg.json'
$DIR/analyze_clusters --method="ami" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-agg-pca.json'
$DIR/analyze_clusters --method="ami" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift.json'
$DIR/analyze_clusters --method="ami" $DIR/$NAME'-groundtruth.json' $DIR/$NAME'-meanshift-pca.json'

