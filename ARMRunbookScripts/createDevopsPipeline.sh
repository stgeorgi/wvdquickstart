#  Create a new build pipeline in the newly created DevOps project, based on the YAML file that was pulled from the GitHub repository.
#  After completion of this script, the pipeline will automatically start running.
#
#  Input parameters:
#     [Required]  ${1}  <orgName>        
#     [Required]  ${2}  <projectName>         
#     [Required]  ${3}  <azureAdminUpn>             
#     [Required]  ${4}  <keyvaultName> 


az login --identity
secret="$(az keyvault secret show --name 'azurePassword' --vault-name ${4} --query '[value]' -o tsv)" 
az logout

az login -u ${3} -p $secret

az extension add --name azure-devops
az pipelines create --name "WVD QuickStart" --organization "https://dev.azure.com/${1}" --project ${2} --repository ${2} --repository-type "tfsgit" --branch "master" --yml-path "QS-WVD/pipeline.yml"
