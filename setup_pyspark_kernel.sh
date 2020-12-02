#!/bin/bash

# **************************************************************************************************************
# This script sets up jupyter settings and kernel on behalf of a user.
# Dependencies:
#   conda virtualenv with jupyter, ipython, R modules installed in a known place,
#   typically /home2/anaconda3
#
# usage:
# /home2/Tools/setup_pyspark_kernel.sh 8888 10.111.22.2
#
# README:
# The script contains 3 important functions:
# 1. createPySparkSetupFile() -  This function creates a 00-setup.py file in the PySPark 
# profile that the user defines. It will be created under ~/.ipython/ directory
#
# 2. createJupyterKernelFile() -  This function creates a kernel.json file for the specified CONDA_VENVNAME.
# It will be created under /home2/anaconda3/envs/py36/share/jupyter/kernels/ directory
# 
# NOTE: Un-comment the above function, if you need to generate a kernel.json file only. 
# This function can only be performed as a sshuser. Re-comment the function after usage.
#
# 3. modifyJupyterConfigSettings() -  This function modifies the jupyter_notebook_config.py file 
# ~/.jupyter directory. It replaces the existing PORT and IP address on which the jupyter notebook runs
# **************************************************************************************************************

# Global Variables

# anaconda location and virtual environment location
ANACONDA_HOME=${ANACONDA_HOME:-"/home2/anaconda3"}
JUPYTER_KERNEL_HOME=${JUPYTER_KERNEL_HOME:-"/home2/anaconda3/envs/py36/share/jupyter"} # Location for all common jupyter kernels used by BHF team
CONDA_VENVNAME=${CONDA_VENVNAME:-"py36"}
CONDA_VENVPYTHON=$ANACONDA_HOME/envs/$CONDA_VENVNAME/bin/python

# Location of the PySpark kernel configuration
JUPYTER_KERNEL_NAME=${JUPYTER_KERNEL_NAME:-"PySpark_${CONDA_VENVNAME}"}
JUPYTER_KERNEL_SETUP_FILE=~/.ipython/profile_$JUPYTER_KERNEL_NAME/startup/00-setup.py
JUPYTER_KERNEL_DIR=$JUPYTER_KERNEL_HOME/kernels
PYSPARK_KERNEL_DIR=$JUPYTER_KERNEL_DIR/$JUPYTER_KERNEL_NAME
PYSPARK_KERNEL_FILE=$PYSPARK_KERNEL_DIR/kernel.json

# Global values to change, if the number os resources assigned to the PySpark jobs needs to increased ot decreased.
PYSPARK_DRIVER_MEMORY=24G
PYSPARK_NUM_OF_EXECUTORS=14
PYSPARK_EXECUTOR_CORES=4
PYSPARK_EXECUTOR_MEMORY=32G
PYSPARK_EXEC_QUEUE=default

# Configure the jupyter notebook configuration and assign the port for each user
JUPYTER_NOTEBOOK_CONFIG=$HOME/.jupyter/jupyter_notebook_config.py

# Accept the user provided port and IP address. If no values are provided, default to port = 8888, IP = 10.213.20.65
JUPYTER_SERVER_PORT=$1
JUPYTER_SERVER_HOST_IP=$2

JUPYTER_SERVER_PORT=${JUPYTER_SERVER_PORT:-8888}
JUPYTER_SERVER_HOST_IP=${JUPYTER_SERVER_HOST_IP:-10.213.20.65}

# This function is designed to test the exit codes used in the tacking the state changes in this trip
function checkRetVal() {

    # check exit codes
    RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
        echo "Error: completed with non zero exit code of ${RETVAL}"
        exit 1
    fi
}

# files and directories touched by this script
JUPYTER_LOCALCACHE_DIR=$HOME/.local


function modifyJupyterConfigSettings() {

    # Linux statements needed to search and replace the following details in the Jupyter Notebook
    # 1. Port Number - Assigned port number to the user
    # 2. Open Browser - Set to false
    # 3. IP address, where the jupyter notebook gets launched (Dev1, Dev2, Primary)

    # Generate jupyter config
    echo "Generating Jupyter config"

    # first need to do an overwrite check for $JUPYTER_NOTEBOOK_CONFIG
    if [ -e $JUPYTER_NOTEBOOK_CONFIG ]; then
        echo "making a backup of Jupyter config $JUPYTER_NOTEBOOK_CONFIG"
        /bin/mv -f $JUPYTER_NOTEBOOK_CONFIG "$JUPYTER_NOTEBOOK_CONFIG.bak"
        checkRetVal
    fi

    # Assuming that the python environment is already activated
    jupyter notebook --generate-config
    checkRetVal

    # need to make a modification to the jupyter notebook config file
    echo "Modifying $JUPYTER_NOTEBOOK_CONFIG"
    if [ ! -e $JUPYTER_NOTEBOOK_CONFIG ]; then
        echo "Can't find $JUPYTER_NOTEBOOK_CONFIG!"
        exit 1
    fi

    # # c.NotebookApp.port = 8888 in jupyter_notebook_config.py
    sed -i.bak "s#\#[[:space:]]*c.NotebookApp.port = 8888#c.NotebookApp.port = ${JUPYTER_SERVER_PORT}#" $JUPYTER_NOTEBOOK_CONFIG

    # # Set c.NotebookApp.open_browser to False in jupyter_notebook_config.py
    sed -i.bak "s#\#[[:space:]]*c.NotebookApp.open_browser = True#c.NotebookApp.open_browser = False#" $JUPYTER_NOTEBOOK_CONFIG

    # # c.NotebookApp.ip = 'localhost' in jupyter_notebook_config.py
    sed -i.bak "s#\#[[:space:]]*c.NotebookApp.ip = 'localhost'#c.NotebookApp.ip = '${JUPYTER_SERVER_HOST_IP}'#" ${JUPYTER_NOTEBOOK_CONFIG}
}


function createPySparkSetupFile() {

    # create the pyspark profile for the user
    echo "Creating the $JUPYTER_KERNEL_NAME profile"
    ipython profile create $JUPYTER_KERNEL_NAME
    checkRetVal

    # find the py4j lib relative path
    PY4J_LIB_LOC=$(find -L $SPARK_HOME -name *py4j*.zip -printf "%P")
    if [ -z $PY4J_LIB_LOC ]; then
        echo "py4j library is not found"
        checkRetVal
    fi

    # we create $JUPYTER_KERNEL_SETUP_FILE next but do check first to see if this
    # file exists

    if [ -e $JUPYTER_KERNEL_SETUP_FILE ]; then
        echo "making a backup of $JUPYTER_KERNEL_SETUP_FILE"
        /bin/mv -f $JUPYTER_KERNEL_SETUP_FILE "$JUPYTER_KERNEL_SETUP_FILE.bak"
        checkRetVal
    fi

    # create pyspark setup file
    echo "import os" >> ${JUPYTER_KERNEL_SETUP_FILE}
    echo "import sys" >> ${JUPYTER_KERNEL_SETUP_FILE}
    echo "spark_home = os.environ.get('SPARK_HOME', None)" >> ${JUPYTER_KERNEL_SETUP_FILE}
    echo "sys.path.insert(0, os.path.join(spark_home, 'python'))" >> ${JUPYTER_KERNEL_SETUP_FILE}
    echo "sys.path.insert(0, os.path.join(spark_home, '${PY4J_LIB_LOC}'))" >> ${JUPYTER_KERNEL_SETUP_FILE}
    echo "exec( open(os.path.join(spark_home, 'python/pyspark/shell.py')).read())" >> ${JUPYTER_KERNEL_SETUP_FILE}
}


function createJupyterKernelFile() {
    
    # create the kernel directory
    echo "Creating $PYSPARK_KERNEL_DIR"
    if  [ ! -d $PYSPARK_KERNEL_DIR ]; then
        /bin/mkdir -p $PYSPARK_KERNEL_DIR
        checkRetVal
    fi

    PYSPARK_CONDA_PYTHON="./ANACONDA/${CONDA_VENVNAME}/bin/python"

    # ------------------
    # create kernel file

    cat <<EOF > ${PYSPARK_KERNEL_FILE}
{
    "display_name": "${JUPYTER_KERNEL_NAME}",
    "language": "python",
    "argv": [
        "$CONDA_VENVPYTHON",
        "-m",
        "ipykernel",
        "--profile=$JUPYTER_KERNEL_NAME",
        "-f",
        "{connection_file}"
    ],
    "env": {
        "SPARK_HOME": "$SPARK_HOME",
        "SPARK_CONF_DIR": "/usr/hdp/current/spark2-client/conf",
        "PYSPARK_PYTHON": "${PYSPARK_CONDA_PYTHON}/envs/py36/bin/python",
        "PYSPARK_DRIVER_PYTHON": "${ANACONDA_HOME}/envs/py36/bin/python",
        "PYSPARK_SUBMIT_ARGS": "--name JupyterNB_${JUPYTER_KERNEL_NAME} --master yarn --deploy-mode client --conf spark.hadoop.metastore.catalog.default=hive --conf spark.yarn.access.hadoopFileSystems=abfs://hdfs-research-migrated@bdsadlsuse2rs.dfs.core.windows.net --archives hdfs://mycluster/apps/py36_az.zip#ANACONDA --conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=${PYSPARK_CONDA_PYTHON} --driver-memory ${PYSPARK_DRIVER_MEMORY} --num-executors ${PYSPARK_NUM_OF_EXECUTORS} --executor-cores ${PYSPARK_EXECUTOR_CORES} --executor-memory ${PYSPARK_EXECUTOR_MEMORY} --queue ${PYSPARK_EXEC_QUEUE} pyspark-shell"
    }
}
EOF
    checkRetVal
}


# Capture the python version associated to the virtual environment
PYTHON_VERSION=$(${CONDA_VENVPYTHON} -V 2>&1 | grep -Po '(?<=Python )(.+)')
if [[ -z "$PYTHON_VERSION" ]]
then
    echo "No Python binary found!" 
fi

# Print the global variable details
echo "***** Spark and Python Settings *****"
echo "Spark Version     :   ${SPARK_HOME}"
echo "Python Version    :   ${PYTHON_VERSION}"

echo "***** Jupyter Settings *****"
echo "Jupyter User Port             :   $JUPYTER_SERVER_PORT"
echo "Jupyter Server Host IP        :   $JUPYTER_SERVER_HOST_IP"
echo "Jupyter PySpark Kernel Name   :   $JUPYTER_KERNEL_NAME"

# need to delete ~/.local if it exists or these changes will not be captured by jupyter
if [ -d $JUPYTER_LOCALCACHE_DIR ]; then
    # directory exists
    echo "** WARNING! ** "
    echo "You have possible previous Jupyter/iPython values cached in ${JUPYTER_LOCALCACHE_DIR}"
    echo "Please delete this directory by running \"rm -r ${JUPYTER_LOCALCACHE_DIR}"\"
    echo "Otherwise changes made by this script will not take effect."
    echo -n "OK to continue? [Y/N] "
    read response
    
    # convert to lowercase
    lc_response=`echo "$response" | awk '{print tolower($0)}'`
    if [ "$lc_response" = "n" -o "$lc_response" = "no" ]; then
    echo "You've elected to not continue. Quitting"
    exit 1
    # /bin/rm -rf $JUPYTER_LOCALCACHE_DIR
    fi
fi

# activate the special conda virtual env
echo "Activating the conda virtual environment"
source ${ANACONDA_HOME}/bin/activate ${CONDA_VENVNAME}
checkRetVal

# createPySparkSetupFile
createJupyterKernelFile # Un-comment the following line, if you need to generate a kernel.json file. This function can only be performed as a sshuser
# modifyJupyterConfigSettings

# deactivate the virtual environment
echo "Deactivating virtualenv"
source $ANACONDA_HOME/bin/deactivate 

echo "End of script!!"

exit 0