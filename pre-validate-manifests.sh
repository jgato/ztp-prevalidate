#! /bin/bash
# script to validate that Manifests are correct
# it execute the Kustomize plugins that will be
# executed later on ArgoCD
# it allows to check it before pushing changes
# to be used on our CI/CD

BASEDIR=$1
ZTP_SITE_GENERATOR_IMG="quay.io/openshift-kni/ztp-site-generator:latest"

if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Usage:"
    echo "  $(basename $0) PATH_WITH_MANIFESTS"
    exit 1
fi

if [[ ! -d $BASEDIR ]]; then
    echo "FATAL: $BASEDIR is not a directory" >&2
    exit 1
fi

echo "Cheking yaml syntax"
yamllint ${BASEDIR} -d relaxed --no-warnings

if [[ $? != 0  ]]; then
    echo "Error on yamls systax"
    exit 1
fi

echo "Checking Management cluster connectivity"
oc get clusterversion > /dev/null

if [[ $? != 0  ]]; then
    echo "Error connecting OCP cluster. Is kubeconfig correctly exported/configured?"
    exit 1
fi

echo "Checking Siteconfig/PGT Manifests with Kustomize plugins"
export KUSTOMIZE_PLUGIN_HOME=/tmp/ztp-kustomize-plugin/

mkdir -p /tmp/ztp-kustomize-plugin/
podman cp $(podman create --name policgentool --rm ${ZTP_SITE_GENERATOR_IMG=}):/kustomize/plugin/ran.openshift.io /tmp/ztp-kustomize-plugin/
podman rm -f policgentool

kustomize build ${BASEDIR} --enable-alpha-plugins |  sed -E -e 's/(namespace: )(.+)/\1default\n/g' | oc apply --dry-run=server -f -

if [[ $? != 0  ]]; then
    echo "Error processing manifests"
    exit 1
fi

exit 0

