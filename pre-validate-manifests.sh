#! /bin/bash
# script to validate that Manifests are correct
# it execute the Kustomize plugins that will be
# executed later on ArgoCD
# it allows to check it before pushing changes
# to be used on our CI/CD

VALIDATE_SRC=$1
ZTP_SITE_GENERATOR_IMG="quay.io/openshift-kni/ztp-site-generator:latest"
PRE_VALIDATE_ERROR_LOG="/tmp/pre-validate-error.log"
ERRORS=0
FILES=()

get_plugins()
{
    export KUSTOMIZE_PLUGIN_HOME=/tmp/ztp-kustomize-plugin/

    mkdir -p /tmp/ztp-kustomize-plugin/
    podman cp $(podman create --name policgentool --rm ${ZTP_SITE_GENERATOR_IMG=} > /dev/null):/kustomize/plugin/ran.openshift.io /tmp/ztp-kustomize-plugin/
    podman rm -f policgentool
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
fi

get_plugins

echo "Checking Management cluster connectivity"
oc get clusterversion > /dev/null

if [[ $? != 0  ]]; then
    echo "Error connecting OCP cluster. Is kubeconfig correctly exported/configured?"
    exit 1
fi

echo "======================================================="
echo "| Cheking ZTP Manifests in kustomization.yaml         |"
echo "======================================================="



echo -ne "\t * Checking Siteconfig/PGT Manifests in kustomization.yaml: "

#kustomize build ${VALIDATE_SRC} --enable-alpha-plugins |  sed -E -e 's/(namespace: )(.+)/\1default\n/g' | oc apply --dry-run=server -f - >${PRE_VALIDATE_ERROR_LOG} 2>&1
if [[ $? != 0  ]]; then
    echo "X"
    ERRORS=1
else
    echo "OK"
fi

FILES=('/home/jgato/Projects-src/billerica-gogs/ztp-belerica/site-configs/intel-1-sno-1.yaml' '/home/jgato/Projects-src/billerica-gogs/ztp-belerica/site-configs/bellerica-sno1.yaml')

echo "======================================================="
echo "| Cheking yaml syntax for files in kustomization.yaml |"
echo "======================================================="

for FILE in ${FILES[@]}
do
    echo -e  "\t $FILE"
    echo -ne "\t - yamllint validation: "
    yamllint ${FILE} -d relaxed --no-warnings >> ${PRE_VALIDATE_ERROR_LOG} 2>&1

    if [[ $? != 0  ]]; then
        echo "X"
        ERRORS=1
    else
        echo "OK"
    fi

done

exit ${ERRORS}

