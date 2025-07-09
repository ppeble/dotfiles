# Initialize rbenv
eval "$(rbenv init -)"

# Add $HOME/bin to path
export PATH="$HOME/bin:$PATH"

# Pip/Python3 bin path
export PATH="$HOME/Library/Python/3.7/bin:$PATH"

# Go bin directory
export PATH=$PATH:$(go env GOPATH)/bin

# Add /usr/local/bin
export PATH=$PATH:/usr/local/bin/

# Set up kubectl krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Set up homebrew curl
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# Add istioctl
export PATH="$HOME/.istioctl/bin:$PATH"

# Brew autocomplete
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

#OktaAWSCLI
if [[ -f "$HOME/.okta/bash_functions" ]]; then
    . "$HOME/.okta/bash_functions"
fi

if [[ -d "$HOME/.okta/bin" && ":$PATH:" != *":$HOME/.okta/bin:"* ]]; then
    PATH="$HOME/.okta/bin:$PATH"
fi

# Adding this based on ember-app README
export PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig"

# Path to your oh-my-zsh installation.
export ZSH="/Users/ppeble/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="simple"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
  git
  history
  docker
)

source $ZSH/oh-my-zsh.sh

# My personal settings
set -o vi
export DEV_DIR='/Users/ppeble/dev'

# Only call compinit if the zcompdump is at least a day old
if [ $(date +'%j') != $(/usr/bin/stat -f '%Sm' -t '%j' ${ZDOTDIR:-$HOME}/.zcompdump) ]; then
  compinit
else
  compinit -C
fi

# Custom aliases and functions
alias ll='ls -ltr'
alias lla='ls -ltra'
alias v='vim'
alias nv='nvim'
alias zshrc_edit='nvim ~/.zshrc'
alias zshrc_reload='source ~/.zshrc'
alias zshrc_backup='cp ~/.zshrc ~/Dropbox/.'

## Navigation
alias dev='cd $DEV_DIR'
alias devp='cd $DEV_DIR/ppeble'
alias hosted='cd $DEV_DIR/hosted'
alias ember-app='cd $DEV_DIR/ember-app'
alias localdev='cd $DEV_DIR/localdev'
alias localdev-logs='localdev; cd logs;'

## git
alias add-ssh-keys='ssh-add --apple-use-keychain ~/.ssh/id_rsa; ssh-add --apple-use-keychain ~/.ssh/acdevops-admin.pem; ssh-add --apple-use-keychain ~/.ssh/staging-elk.pem; ssh-add --apple-use-keychain ~/.ssh/staging-admin.pem; ssh-add --apple-use-keychain ~/.ssh/admin.pem; ssh-add --apple-use-keychain ~/.ssh/platformsvc_prod.pem;'
alias gum='git checkout master; git pull'
alias gurm='gurb master'
alias gurd='gurb develop'

function gurb() {
  if [ "$#" -eq 0 ]; then
    echo "You must provide a branch!"
    return;
  fi

  branch=$1

  echo "Rebasing '$branch' from upstream to origin version ..."

  git checkout $branch;
  lrc=$?;
  if ((lrc!=0)); then
    echo "Failed to checkout '$branch'!";
    return $lrc;
  fi

  git fetch upstream;
  lrc=$?;
  if ((lrc!=0)); then
    echo "Failed to fetch from upstream!";
    return $lrc;
  fi

  git rebase upstream/$branch;
  lrc=$?;
  if ((lrc!=0)); then
    echo "Failed on rebase upstream/$branch!";
    return $lrc;
  fi

  git push origin $branch
}

function gar_github() {
  git remote add upstream git@github.com:$1/$2.git;
}

function gar_gitlab() {
  git remote add upstream git@gitlab-ssh.devops.app-us1.com:$1/$2.git;
}

alias git-config-personal='git config user.name "Phil Peble"; git config user.email "philpeble@gmail.com"'
alias git-config-activecampaign='git config user.name "Phil Peble"; git config user.email "ppeble@activecampaign.com"'
alias git-config-travis='git config user.name "Phil Peble"; git config user.email "phil@travis-ci.com"'

alias amend-prev-commit-author-travis='git-config-travis; git commit --amend --reset-author'
alias amend-prev-commit-author-personal='git-config-personal; git commit --amend --reset-author'

alias reset-ssh-agent='ssh-add -D'

## go
alias gohome='cd ~/dev/go'
alias gcov='gocov convert test.cov | gocov-html > test-cov.html'
alias swagger="docker run --rm -it  --user $(id -u):$(id -g) -e GOPATH=$HOME/go:/go -v $HOME:$HOME -w $(pwd) quay.io/goswagger/swagger"

## entr
alias tgcur="ls -d * | entr -c -s 'go test ./.'"

## Docker
alias ds='docker stats'
alias dcp='docker-compose ps'
alias dmenv_localdev='eval $(docker-machine env)'
alias dmenv_minikube='eval $(minikube docker-env)'
alias dmstart='docker-machine start default'
alias dmstop='docker-machine stop'

## ActiveCampaign

### Relief worker helpers
alias start-relief-workers-localdev='localdev; docker-compose up relief-workers hosted; cd -'
alias relief-workers-bash='localdev; docker-compose exec relief-workers-workspace bash; cd -'

### Hosted Helpers
alias stop-localdev='localdev; docker-compose down; cd -'
alias start-and-build-hosted='localdev; docker-compose up -d --build hosted; cd -'
alias stop-and-clean-localdev='localdev; docker-compose down -v --remove-orphans; cd -'
alias hosted-workspace='localdev; docker-compose exec --user=localdev hosted-workspace bash; cd -'
alias localdev-workspace-up='localdev; docker-compose up -d --build localdev-workspace; cd -'
alias localdev-workspace='localdev; docker-compose exec localdev-workspace bash; cd -'
alias hosted-mysql='localdev; docker-compose exec all-mysql bash; cd -'
alias hosted-logs='tail -f $DEV_DIR/localdev/logs/hosted/logs/hosted-v1.log'
alias start-hosted-ngrok='ngrok http -host-header=rewrite hosted.localdev:80'
alias start-grouper='docker-compose up -d --build grouper'
alias stop-grouper='docker-compose stop grouper grouper-app'
alias grouper-bash='docker-compose run grouper-app bash'
alias start-custom-fields='docker-compose up -d --build custom-fields'
alias custom-fields-bash='localdev; docker-compose exec --user=localdev custom-fields-workspace bash; cd -'

### ARC/ActiveCampaign.com helpers
alias start-and-build-site='localdev; docker-compose up -d --build site; cd -'

function deep-clean-hosted-images() {
  docker rmi localdev_hosted-scripts;
  docker rmi localdev_hosted-workspace;
  docker rmi localdev_localdev-workspace;
  docker rmi localdev_localdev-proxy;
  docker rmi localdev_hosted-fpm;
  docker rmi localdev_hosted-scripts-fpm;
  docker rmi localdev_localdev-dnsmasq;
  docker rmi localdev_hosted;
  docker rmi localdev_localstack;
  docker rmi localdev_all-mysql;
  docker rmi localdev_custom-fields;
  docker rmi localdev_custom-fields-init;
  docker rmi localdev_custom-fields-workspace;
  docker rmi localdev_custom-fields-fpm;
  docker rmi localdev_grouper;
  docker rmi localdev_grouper-app;
  docker rmi nginx;
  docker rmi localdev_wiremock;
}

function load-fakeql-data-to-localdev() {
  if [[ $# -eq 0 ]]; then
    echo "You must at least provide the target database!"
    return;
  fi

  database_name=$1
  sql_file_location=$2

  if [[ -z "${sql_file_location}" ]]; then
    echo "No SQL file provided, defaulting to ~/dev/fakeql/tmp.sql"
    sql_file_location="/Users/ppeble/dev/fakeql/tmp.sql"
  fi

  echo "Loading data ..."
  eval docker-compose exec -T all-mysql mysql -u root '$database_name' < $sql_file_location
}

### ember-app helper
alias eab='ember build --watch'

function eatf() {
  $filter=$1

  ember test --server --filter="$1"
}

### Kubernetes
alias k-auth-staging='okta-aws staging sts get-caller-identity'
alias k-auth-prod='okta-aws prod sts get-caller-identity'

function launch-network-utils-pod() {
  k run network-utils -it --image amouat/network-utils --generator=run-pod/v1 --command=true -n $1 -- /bin/sh
}

function k() {
  kubectl $@
}

function k-set-ns() {
  k config set-context --current --namespace=$1
}

function k-unset-ns() {
  k config unset contexts.default.namespace
}

function k-set-pf() {
  k port-forward $1 $2
}

function kd() {
  k devops $@
}

function kd-set-ns() {
  k devops config set-context --current --namespace=$1
}

function kd-unset-ns() {
  k devops config unset contexts.default.namespace
}

function kdev() {
  k dev $@
}

function kdev-set-ns() {
  k dev config set-context --current --namespace=$1
}

function kdev-unset-ns() {
  k dev config unset contexts.default.namespace
}

function ks() {
  k staging $@
}

function kse() {
  k staging elevated $@
}

function ks-set-ns() {
  k staging config set-context --current --namespace=$1
}

function ks-unset-ns() {
  k staging config unset contexts.arn:aws:eks:us-east-1:111675434946:cluster/ac-staging-k8s-cluster.namespace
}

function kse-set-ns() {
  k staging elevated config set-context --current --namespace=$1
}

function kse-unset-ns() {
  k staging elevated config unset contexts.arn:aws:eks:us-east-1:111675434946:cluster/ac-staging-k8s-cluster.namespace
}

function kp() {
  k production $@
}

function kpe() {
  k production elevated $@
}

function kp-set-ns() {
  k production config set-context --current --namespace=$1
}

function kp-unset-ns() {
  k production config unset contexts.arn:aws:eks:us-east-1:113901497002:cluster/ac-prod-k8s-cluster.namespace
}

function decode_secret() {
  secret=$1
  field=$2
  kubeconfig=$3

  k get secret ${secret} -o json --kubeconfig ${kubeconfig} | jq -r '.data' | jq --arg field "${field}" -r '.[$field]' | base64 -d
}

# ECR helpers
alias ecr-docker-login-devops='AWS_PROFILE=devops aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 102167438644.dkr.ecr.us-east-1.amazonaws.com'
alias ecr-docker-login-staging='AWS_PROFILE=staging aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 111675434946.dkr.ecr.us-east-1.amazonaws.com'
alias ecr-docker-login-production='AWS_PROFILE=production aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 113901497002.dkr.ecr.us-east-1.amazonaws.com'

# aws cli errors
function get-ec2-logs() {
  env=$1
  instance_id=$2

  AWS_PROFILE="${env}" aws ec2 get-console-output --instance-id "${instance_id}" --output text --latest --query Output
}

### Ambassador helpers
alias ambassador-dev-logs='stern -n ambassador api-gateway-ambassador'
alias ambassador-staging-logs='stern -n ambassador api-gateway-ambassador --kubeconfig ~/.kube/config.k8s-staging'
alias ambassador-test-staging-logs='stern -n ambassador api-gateway-ambassador-test --kubeconfig ~/.kube/config.k8s-staging'

alias ratelimit-dev-logs='stern -n ratelimit api-gateway-ratelimit'
alias ratelimit-staging-logs='stern -n ratelimit staging --kubeconfig ~/.kube/config.k8s-staging'

alias clean-ambassador-test-artifacts='kubectl delete namespaces -l scope=AmbassadorTest; kubectl delete all -l scope=AmbassadorTest -n default; kubectl delete pod kat -n default; delete-ambassador-test-crds;'
alias set-ambassador-build-env='export DEV_KUBECONFIG="/Users/ppeble/.kube/ambassador-kubeconfig.yaml"; unset DEV_REGISTRY;'
alias build-ambassador-docker-images='set-ambassador-build-env; make images'


function build-and-import-ambassador-docker-images-to-k3d() {
  set-ambassador-build-env
  build-ambassador-docker-images
  import-ambassador-docker-images-to-k3d $@
}

function import-ambassador-docker-images-to-k3d() {
  k3d import-images --name ac-platform ambassador:$1
  k3d import-images --name ac-platform kat-client:$1
  k3d import-images --name ac-platform kat-server:$1
}

function delete-ambassador-test-crds() {
  kd delete crd consulresolvers.getambassador.io
  kd delete crd filters.getambassador.io
  kd delete crd authservices.getambassador.io
  kd delete crd kubernetesendpointresolvers.getambassador.io
  kd delete crd kubernetesserviceresolvers.getambassador.io
  kd delete crd logservices.getambassador.io
  kd delete crd mappings.getambassador.io
  kd delete crd modules.getambassador.io
  kd delete crd ratelimitservices.getambassador.io
  kd delete crd tcpmappings.getambassador.io
  kd delete crd tlscontexts.getambassador.io
  kd delete crd tracingservices.getambassador.io
  kd delete crd hosts.getambassador.io
}

## Stern

function stern-staging() {
  stern $1 --kubeconfig ~/.kube/config.k8s-staging
}

function stern-prod() {
  stern $1 --kubeconfig ~/.kube/config.k8s-production
}

##  ac-platform helpers
function acp-set-dev() {
  mv ~/.activecampaign/ac-platform ~/.activecampaign/ac-platform-backup
  ln -s ~/dev/devops/ac-platform ~/.activecampaign/ac-platform
}

function acp-reset-to-official() {
  rm ~/.activecampaign/ac-platform
  mv ~/.activecampaign/ac-platform-backup ~/.activecampaign/ac-platform
}

## gitlab administration
alias bastion-devops-k8s-developer="ssh ec2-user@54.82.115.75 -A"
alias bastion-devops-gitlab="ssh ec2-user@34.234.118.120 -A"
alias bastion-devops-k8s-devops="ssh ec2-user@3.220.78.245 -A"
alias bastion-devops-eu-central-1="ssh ec2-user@18.156.56.51 -A"
alias bastion-devops-ap-southeast-2="ssh ec2-user@54.153.200.83 -A"
alias bastion-staging-devops="ssh ec2-user@3.230.221.160 -A"
alias bastion-staging-infra="ssh ec2-user@54.145.62.238 -A"
alias bastion-staging-us-east="ssh ec2-user@3.209.193.221 -A"
alias bastion-staging-k8s-staging="ssh ec2-user@54.81.88.65 -A"
alias bastion-prod-devops="ssh ec2-user@3.225.171.193 -A"
alias bastion-prod-k8s-prod="ssh ec2-user@18.213.183.17 -A"
alias bastion-prod-us-east="ssh ec2-user@52.2.247.123 -A"

## Developer Portal Helpers
alias cells='cd $DEV_DIR/platform-automation/deployments/cells'
alias applications='cd $DEV_DIR/platform-automation/deployments/applications'
alias dp-db-ssh-tunnel='ssh -L 5432:developer-portal-db.cluster-cljiwqgzrnwo.us-east-1.rds.amazonaws.com:5432 ec2-user@34.234.118.120'
alias dp-platformsvc-prod-ssh-tunnel='ssh -L 5432:platformsvc-pg-prod.cluster-ro-cmruqscj51mc.us-east-1.rds.amazonaws.com:5432 ec2-user@bastion.platformsvc.app-us1.com'

## Multi Region Helpers

# Usage example: generate-cell-kubeconfig product-aws-usw2-s-1 us-west-2 staging
function generate-cell-kubeconfig() {
  cell=$1
  region=$2
  profile=$3

  aws eks update-kubeconfig --profile ${profile} --region ${region} --name ${cell} --kubeconfig ~/.kube/config.${cell}
}

## Terraform
function tf() {
  terraform $@
}

# Initializers and other configs
export NVM_DIR="$HOME/.nvm"

# Lazy load
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  NODE_GLOBALS=(`find $NVM_DIR/versions/node -maxdepth 3 -type l -wholename '*/bin/*' | xargs -n1 basename | sort | uniq`)
  NODE_GLOBALS+=("node")
  NODE_GLOBALS+=("nvm")

  # Lazy-loading nvm + npm on node globals
  load_nvm () {
    echo "🚨 NVM not loaded! Loading now..."
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # this loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  }

  # Making node global trigger the lazy loading
  for cmd in "${NODE_GLOBALS[@]}"; do
    eval "${cmd}(){ unset -f ${NODE_GLOBALS}; load_nvm; ${cmd} \$@ }"
  done

  unset cmd NODE_GLOBALS
fi

# Set GOPRIVATE so it pulls private packages appropriately, see https://pkg.go.dev/cmd/go#hdr-Configuration_for_downloading_non_public_code
export GOPRIVATE=gitlab.devops.app-us1.com/platform-automation/account-maintenance

# add Pulumi to the PATH
export PATH=$PATH:$HOME/.pulumi/bin

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Adding direnv setup
eval "$(direnv hook zsh)"

export PATH="$HOME/.poetry/bin:$PATH"

# phpbrew
#[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc

source /Users/ppeble/.activecampaign/ac-platform/shell-init.sh

# add KUBECONFIG by ac-platform
export KUBECONFIG=/Users/ppeble/.kube/config

export PATH="$PATH:/Users/ppeble/.local/bin"

# Maven path crap
export PATH="$PATH:/Users/ppeble/bin/apache-maven-3.9.3/bin"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/ppeble/.sdkman"
[[ -s "/Users/ppeble/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/ppeble/.sdkman/bin/sdkman-init.sh"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
