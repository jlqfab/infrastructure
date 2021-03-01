# check whether the tool destinations file has changed
TOOL_DEST_FILE_PATH="files/galaxy/dynamic_job_rules/pawsey/dynamic_rules/tool_destinations.yml"
TOOL_DEST_UPDATED=$(git diff --name-only $GIT_PREVIOUS_COMMIT $GIT_COMMIT | cat | grep $TOOL_DEST_FILE_PATH)

if [ ! "$TOOL_DEST_UPDATED" ]; then
    # nothing to do
    echo "No updates to tool destinations"
    exit 0
fi

# Activate the virtual environment on jenkins. If this script is being run for
# the first time we will need to set up the virtual environment
VIRTUALENV="../.ansible_venv"
REQUIREMENTS_FILE="jenkins/requirements.txt"
CACHED_REQUIREMENTS_FILE="$VIRTUALENV/cached_requirements.txt"

[ ! -d $VIRTUALENV ] && virtualenv -p python3 $VIRTUALENV
# shellcheck source=../.venv3/bin/activate
. "$VIRTUALENV/bin/activate"

# if requirements change, reinstall requirements
[ ! -f $CACHED_REQUIREMENTS_FILE ] && touch $CACHED_REQUIREMENTS_FILE
if [ "$(diff $REQUIREMENTS_FILE $CACHED_REQUIREMENTS_FILE)" ]; then
pip install -r $REQUIREMENTS_FILE
cp $REQUIREMENTS_FILE $CACHED_REQUIREMENTS_FILE
fi

VENV_PATH=".venv3"
virtualenv -p python3 $VENV_PATH
. $VENV_PATH/bin/activate

ansible-playbook -i hosts pawsey_update_job_conf_playbook.yml --private-key $JENKINS_KEY -u jenkins_bot --extra-vars "iamjenkins=true"