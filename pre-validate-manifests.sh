#! /bin/bash
# script to validate that Manifests are correct
# it execute the Kustomize plugins that will be
# executed later on ArgoCD
# it allows to check it before pushing changes
# to be used on our CI/CD

# author: Jose Gato Luis <jgato@redhat.com>

#########################
# Some colours for output
#########################

Color_Off='\033[0m'
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple

########################


VALIDATE_SRC=$1
PRE_VALIDATE_ERROR_LOG="/tmp/pre-validate-error-${RANDOM}.log"
ERRORS=0
FILES=()


get_plugins()
{
    export KUSTOMIZE_PLUGIN_HOME=/tmp/ztp-kustomize-plugin/

    mkdir -p /tmp/ztp-kustomize-plugin/
    podman cp $(podman create --name policgentool --rm ${ZTP_SITE_GENERATOR_IMG}):/kustomize/plugin/ran.openshift.io /tmp/ztp-kustomize-plugin/
    if [[ $? != 0  ]]; then
        echo "Error getting plugins"
        podman rm policgentool > /dev/null
        exit 1
    fi
    podman rm policgentool > /dev/null
}

usage()
{
    if [[ $1 == "-h" || $1 == "--help" ||  "$#" -ne 1  ]]; then
        echo "Usage:"
        echo "  $(basename $0) DIR_WITH_KUSTOMIZATION_YAML"
        exit 1
    fi
}


if [[ $1 == "-h" || $1 == "--help" ||  "$#" -ne 1  ]]; then
    usage
fi

if [[ ! -d ${VALIDATE_SRC} || -d ${VALIDATE_SRC}/kustomization.yaml ]]; then
    usage
else
#ensure dir ends with /
    if [[ ${VALIDATE_SRC} != */ ]]; then
        VALIDATE_SRC=${VALIDATE_SRC}/
    fi
fi

oc get clusterversion > /dev/null

if [[ $? != 0  ]]; then
    echo "Error connecting OCP cluster to simulate/validate Resources. Is kubeconfig correctly exported/configured?"
    exit 1
fi

ZTP_SITE_GENERATOR_IMG=`oc -n openshift-gitops get argocd openshift-gitops -o jsonpath={.spec.repo.initContainers[0].image}`
echo -e "${BGreen}Validating with ztp-site-generator: ${ZTP_SITE_GENERATOR_IMG}${Color_Off}"
get_plugins


echo -e "${BYellow}======================================================="
echo "| Cheking yaml syntax for files in kustomization.yaml |"
echo -e "=======================================================${Color_Off}"

FILES=`cat ${VALIDATE_SRC}kustomization.yaml  | yq e '.generators[]'`

for FILE in ${FILES[@]}
do
    echo -e  "\t $FILE"
    echo -ne "\t - yamllint validation: "
    yamllint ${VALIDATE_SRC}/${FILE} -d relaxed --no-warnings &>> ${PRE_VALIDATE_ERROR_LOG}

    if [[ $? != 0  ]]; then
        echo -e "${BRED}Error${Color_Off}"
        ERRORS=1
    else
        echo -e "${BGreen}OK${Color_Off}"
    fi

done

echo -e "${BYellow}======================================================="
echo -e "| Cheking ZTP Manifests in kustomization.yaml        ${LBlue} |"
echo -e "=======================================================${Color_Off}"

echo -ne "\t * Checking Siteconfig/PGT Manifests in kustomization.yaml: "

kustomize build ${VALIDATE_SRC} --enable-alpha-plugins 2> ${PRE_VALIDATE_ERROR_LOG} |  sed -E -e's/(namespace:)(.+)/\1 default\n/g' | oc apply --dry-run=server -f - &>> ${PRE_VALIDATE_ERROR_LOG}
if [[ $? != 0  ]]; then
    echo -e "${BRed}Error${Color_Off}"
    ERRORS=1
else
    echo -e "${BGreen}OK${Color_Off}"
fi


echo "Log details in: ${PRE_VALIDATE_ERROR_LOG}"

exit ${ERRORS}

