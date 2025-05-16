#! /bin/bash

# Read all command line arguments
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            cluster_provider)          cluster_provider=${VALUE} ;;
            cluster_region)          cluster_region=${VALUE} ;;
            cluster_type)              cluster_type=${VALUE} ;;
            cluster_env)              cluster_env=${VALUE} ;;
            cluster_name)              cluster_name=${VALUE} ;;
            namespace)    namespace=${VALUE} ;;   
            repo_username)    repo_username=${VALUE} ;;
            repo_password)    repo_password=${VALUE} ;;
            cluster_fleet_config_sourceRepoURL)    cluster_fleet_config_sourceRepoURL=${VALUE} ;;
            helm_registry_username)    helm_registry_username=${VALUE} ;;
            helm_registry_password)    helm_registry_password=${VALUE} ;;
            *)   
    esac    
done

# TODO
# print  help if needed

# Setup some derived variables
cluster_fleet_config_sourceRepoPath="$cluster_type/$cluster_provider/$cluster_region/$cluster_env/$cluster_name/apps"

# # Testing
# echo "cluster_name = $cluster_name"
# echo "namespace = $namespace"
# echo "opsverse_repo_username = $opsverse_repo_username"
# echo "opsverse_repo_password = $opsverse_repo_password"
# echo "opsverse_application_sourceRepoURL = $opsverse_application_sourceRepoURL"
# echo "opsverse_application_sourceRepoPath = $opsverse_application_sourceRepoPath"
# echo "opsverse_registry_username = $opsverse_registry_username"
# echo "opsverse_registry_password = $opsverse_registry_password"

# Validate that all required inputs are provided
echo ""
echo "Validating input arguments ..."
if [[ -n $cluster_name ]] \
    && [[ -n $namespace ]] \
    && [[ -n $cluster_type ]] \
    && [[ -n $cluster_provider ]] \
    && [[ -n $cluster_region ]] \
    && [[ -n $cluster_env ]] \
    && [[ -n $repo_username ]] \
    && [[ -n $repo_password ]] \
    && [[ -n $cluster_fleet_config_sourceRepoURL ]] \
    && [[ -n $helm_registry_username ]] \
    && [[ -n $helm_registry_password ]];
    #    && [[ -n $opsverse_application_sourceRepoPath ]] \
then
    echo "All required arguments are present. Continuing ..."
else
    echo "Not all required arguments are present. The following arguments are required: "
    echo "  cluster_name"
    echo "  cluster_type"
    echo "  cluster_provider"
    echo "  cluster_region"
    echo "  cluster_env"
    echo "  namespace"
    echo "  repo_username"
    echo "  repo_password"
    echo "  cluster_fleet_config_sourceRepoURL"
    echo "  helm_registry_username"
    echo "  helm_registry_password"
    exit 1
fi

# Validate if kubectl and helm are available
command -v "kubectl" >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "kubectl is not found. Please check if it is installed."
    echo "Exiting ..."
    exit 1
fi

command -v "helm" >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "helm is not found. Please check if it is installed."
    echo "Exiting ..."    
    exit 1
fi

echo ""
echo "Installing ArgoCD CRD"
kubectl apply -f https://raw.githubusercontent.com/aravind-ainions/installer/refs/heads/main/application-crd.yaml
echo "Installing the bootstrap components to the namespace $namespace ..."
helm upgrade --install k8s-bootstrap -n $namespace --create-namespace k8s-bootstrap \
  --repo https://$repo_username:$repo_password@raw.githubusercontent.com/ainions/charts/main \
  --username $helm_registry_username \
  --password $helm_registry_password \
  --set ainions.repo.username=$helm_chart_repo_username \
  --set ainions.repo.password=$helm_chart_repo_password \
  --set ainions.application.sourceRepoURL=$cluster_fleet_config_sourceRepoURL \
  --set ainions.application.sourceRepoPath=$cluster_fleet_config_sourceRepoPath

# echo ""
# echo "Waiting for sealed-secrets component to create the key pair ..."
# sleep 60

# echo "Please save the following public key (base64 encoded)..."
# echo ""
# echo `kubectl get secret -n ${namespace} -l 'sealedsecrets.bitnami.com/sealed-secrets-key=active' -o jsonpath='{.items[].data.tls\.crt}'`
