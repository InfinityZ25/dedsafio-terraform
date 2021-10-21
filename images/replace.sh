#!/bin/bash

# Define some variables
world_file="$1"
world_nether_file="$2"
pattern="server"
containers="minecraft_sv1_1 minecraft_sv2_1 minecraft_sv3_1 minecraft_sv4_1 minecraft_sv5_1 minecraft_sv6_1"

echo "Creating temp directory to decompress files"
# Create a temp directory, decompress everything there, then move it to each container's directory accordingly
mkdir -p tmp/world tmp/world_nether
unzip -qq -d tmp/world/ "$world_file"
unzip -qq -d tmp/world_nether/ "$world_nether_file"

echo "Done decompressing $world_file & $world_nether_file \n"

# Stop all docker bingo instances.
eval "docker stop $containers"

# Iterate through all the subfolders
for dir in *${pattern}*/; do
    # Get the actual name of the folder and expected name of container.
    length=${#dir}
    folder_name=${dir:0:((--length))}
    container_name="minecraft_${folder_name}_1"
    # Log out the begining of the operation
    echo "Replacing files for container $container_name"
    # Delete all world files
    eval "rm -rf ${dir}/world/* ${dir}/world_nether/* ${dir}/world_the_end/*"
    # Decompress new worlds.
    eval "cp -r tmp/world/* ${dir}/world/"
    eval "cp -r tmp/world_nether/* ${dir}/world_nether/"
    # Log out the completion of the operation
    echo "Done replacing files for container $container_name \n"
done

# Change all permissions to be executable by docker
chmod -R 777 *
# Delete temp dir
rm -rf tmp

# Start all the containers back up
eval "docker start $containers"
