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
DISABLE_YAML_LINT=false
DISABLE_REMOTE_CHECK=false


usage()
{
    echo "This script will use ZTP Kustomize generator plugins to pre-validate your local ZTP Manifests. As a previous step to push them to your Git repo, and then, into ArgoCD"
    echo -e
    echo "Usage:"
    echo "  $(basename $0) DIR_WITH_KUSTOMIZATION_YAML [OPTS]"
    echo "  Optional params: "
    echo "   --disable-yaml-lint: no yaml lint validation, useful if you dont have the yamlint validator binary"
    echo "   --disable-remote-check: no check against a remote Openshift/Kubernetes API. In this case, you have to export the ZTP_SITE_GENERATOR_IMG env variable to point where to download ZTP Plugins. Useful, when you dont have access to the Openshift/Kubernetes API"
    echo "   --local-generator-plugins: in this case the generator plugins are not downloaded, export a env variable KUSTOMIZE_PLUGIN_HOME with a path to the plugins."
    echo  -e
    echo " Clarification about the ZTP generator plugins. How are this gathered?"
    echo "   By default, if you dont --disable-remote-check, it means you have a KUBECONFIG exported variable. The script will use the connectivity to the cluster, to find out which version of the plugins are in use. The plugins are automatically downloaded. "
    echo "   If you do  --disable-remote-check the script cannot find out which version of the plugins you are using in your cluster, and you have to manually export the env variable ZTP_SITE_GENERATOR_IMG, with the Container image that contains the plugins. The script will take the plugins from this image."
    echo "   When you dont have any kind of connectivity, you can use your local version  of the plugins with --local-generator-plugins and exporting the plugins with KUSTOMIZE_PLUGIN_HOME"
    exit 1
}

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

check_kustomization_sintax()
{
    yamllint ${VALIDATE_SRC}kustomization.yaml  -d relaxed --no-warnings &>> ${PRE_VALIDATE_ERROR_LOG}

    echo -ne "\t * Checking kustomization.yaml: "

    if [[ $? != 0  ]]; then
        echo -e "${BRed}Error${Color_Off}"
        echo "Log details in: ${PRE_VALIDATE_ERROR_LOG}"
        exit  1
    else
        echo -e "${BGreen}OK${Color_Off}"
    fi
}

if [[ $1 == "-h" || $1 == "--help" || $# -gt 4 ]]; then
    usage
fi

if [[ ! -d ${VALIDATE_SRC} || -d ${VALIDATE_SRC}/kustomization.yaml ]]; then
    usage
else
    if [[ ${VALIDATE_SRC} != */ ]]; then
        VALIDATE_SRC=${VALIDATE_SRC}/
    fi
fi

if [[ " $@ " =~ " --disable-yaml-lint " ]]; then
    DISABLE_YAML_LINT=true
fi

if [[ " $@ " =~ " --disable-remote-check " ]]; then
    DISABLE_REMOTE_CHECK=true
    if [[ -z "${ZTP_SITE_GENERATOR_IMG}" ]]; then
        echo -e "${BRed} When --disable-remote-check, you have to export env variable ZTP_SITE_GENERATOR_IMG ${Color_Off}"
        exit 1
    fi
else
    echo -e "${BGreen}Validating remote access to Openshift/Kubernetes remote API${Color_Off}"

    oc get clusterversion > /dev/null

    if [[ $? != 0  ]]; then
        echo -e "${BRed}Error connecting OCP cluster to simulate/validate Resources. Is kubeconfig correctly exported/configured? or, use --disable-remote-check option${Color_Off}"
        exit 1
    fi

    ZTP_SITE_GENERATOR_IMG=`oc -n openshift-gitops get argocd openshift-gitops -o jsonpath={.spec.repo.initContainers[0].image}`
    echo -e "${BGreen}Validating with ztp-site-generator: ${ZTP_SITE_GENERATOR_IMG}${Color_Off}"
fi

if [[ " $@ " =~ " --local-generator-plugins " ]]; then
    if [[ -z "${KUSTOMIZE_PLUGIN_HOME}" ]]; then
        echo -e "${BRed}When --local-generator-plugins, you have to export env variabel KUSTOMIZE_PLUGIN_HOME with the path to local path to the plugins. If you are using env variable ZTP_SITE_GENERATOR_IMG, it will be ignored.${Color_Off}"
        exit 1
    fi
else
    get_plugins
fi


# first, ensure kustomization.yaml is correct
#
echo -e "${BYellow}======================================================="
echo "| Cheking kustomization.yaml syntax                   |"
echo -e "=======================================================${Color_Off}"

if [[ ! -f  "${VALIDATE_SRC}kustomization.yaml" ]]; then
    echo -e "${BRed}No kustomization file in the folder${Color_Off}"
    exit 1
fi

if [[ "${DISABLE_YAML_LINT}" = true ]]; then
    echo -e "${BGreen} Skip yaml lint as requested. ${Color_Off}"
else
    check_kustomization_sintax
    # second, ensure kustomization.yaml contains files to check
    # if no, we dont even continue

    # ToDo: think on an alternative if there is no yq available
    # or we just force to do --skip-yaml-lint, that would be a pity
    FILES=`cat ${VALIDATE_SRC}kustomization.yaml  | yq e '.generators[]'`
    N_FILES=${#FILES}

    echo -ne "\t * Files to check "

    if [[ ${N_FILES} == 0  ]]; then
        echo -e "${BGreen}Empty. No need to continue.${Color_Off}"
        exit 0
    else
        echo -e "${BGreen}${N_FILES}${Color_Off}"
    fi

    echo -e "${BYellow}======================================================="
    echo "| Cheking yaml syntax for files in kustomization.yaml |"
    echo -e "=======================================================${Color_Off}"

    for FILE in ${FILES[@]}
    do
        echo -e  "\t $FILE"
        echo -ne "\t - yamllint validation: "
        yamllint ${VALIDATE_SRC}/${FILE}  -d relaxed --no-warnings &>> ${PRE_VALIDATE_ERROR_LOG}

        if [[ $? != 0  ]]; then
            echo -e "${BRed}Error${Color_Off}"
            ERRORS=1
        else
            echo -e "${BGreen}OK${Color_Off}"
        fi
    done
fi




echo -e "${BYellow}======================================================="
echo -e "| Cheking ZTP Manifests in kustomization.yaml        ${LBlue} |"
echo -e "=======================================================${Color_Off}"

echo -ne "\t * Checking Siteconfig/PGT Manifests in kustomization.yaml: "

if [[ "${DISABLE_REMOTE_CHECK}" = true ]]; then
    kustomize build ${VALIDATE_SRC} --enable-alpha-plugins 2>> ${PRE_VALIDATE_ERROR_LOG} 1>>/dev/null
else
    kustomize build ${VALIDATE_SRC} --enable-alpha-plugins 2>> ${PRE_VALIDATE_ERROR_LOG} |  sed -E -e's/(namespace:)(.+)/\1 default\n/g' | oc apply --dry-run=server -f - &>> ${PRE_VALIDATE_ERROR_LOG}
fi

if [[ $? != 0  ]]; then
    echo -e "${BRed}Error${Color_Off}"
    ERRORS=1
else
    echo -e "${BGreen}OK${Color_Off}"
fi

echo "Log details in: ${PRE_VALIDATE_ERROR_LOG}"

exit ${ERRORS}

