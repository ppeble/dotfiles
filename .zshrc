# Initialize rbenv
eval "$(rbenv init -)"

# Add $HOME/bin to path
export PATH="$HOME/bin:$PATH"

# Gopath for older projects not using modules
export GOPATH="$HOME/go"

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
  bundler
  history
  docker
)

source $ZSH/oh-my-zsh.sh

# My personal settings
set -o vi
export DEV_DIR='/Users/ppeble/dev'

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
alias container-kit='cd $DEV_DIR/container-kit'
alias hosted='cd $DEV_DIR/hosted'
alias ember-app='cd $DEV_DIR/ember-app'
alias localdev='cd $DEV_DIR/localdev'
alias localdev-logs='localdev; cd logs;'

## git
alias add-ssh-keys='ssh-add -K ~/.ssh/id_rsa'
alias gst='git status'
alias gd='git diff'
alias gds='git diff --staged'
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
alias start-and-build-hosted='localdev; docker-compose up -d --build hosted; cd -'
alias stop-and-clean-hosted='localdev; docker-compose down -v --remove-orphans; cd -'
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
alias k3d-env='export KUBECONFIG="$(k3d get-kubeconfig --name='ac-platform')"'
alias k-auth-staging='okta-aws staging sts get-caller-identity'
alias k-auth-prod='okta-aws prod sts get-caller-identity'

function kd() {
  kubectl $@
}

function kd-set-ns() {
  kubectl config set-context --current --namespace=$1
}

function kd-unset-ns() {
  kubectl config unset contexts.default.namespace
}

function kd-set-pf() {
  kubectl port-forward $1 $2
}

function kd-ambassador-pf() {
  #$POD=$(kubectl get pods -n ambassador -l "app.kubernetes.io/instance"=api-gateway-ambassador -o jsonpath="{.items[0].metadata.name}");
  kubectl port-forward $1 8877
}

function ks() {
  kubectl staging $@
}

function ks-set-ns() {
  kubectl staging config set-context --current --namespace=$1
}

function ks-unset-ns() {
  kubectl staging config unset contexts.arn:aws:eks:us-east-1:111675434946:cluster/ac-staging-k8s-cluster.namespace
}

function kp() {
  kubectl production $@
}

function kp-set-ns() {
  kubectl production config set-context --current --namespace=$1
}

function kp-unset-ns() {
  kubectl production config unset contexts.arn:aws:eks:us-east-1:113901497002:cluster/ac-prod-k8s-cluster.namespace
}

### Ambassador helpers
alias ambassador-dev-logs='stern -n ambassador api-gateway-ambassador'
alias ambassador-staging-logs='stern -n ambassador api-gateway-ambassador --kubeconfig ~/.kube/config.k8s-staging'

alias ratelimit-dev-logs='stern -n ratelimit api-gateway-ratelimit'
alias ratelimit-staging-logs='stern -n ratelimit staging --kubeconfig ~/.kube/config.k8s-staging'

alias delete-ambassador-test-artifacts='kubectl delete namespaces -l scope=AmbassadorTest; kubectl delete all -l scope=AmbassadorTest -n default; kubectl delete pod kat -n default;'
alias set-ambassador-build-env='export DEV_KUBECONFIG="/Users/ppeble/.kube/ambassador-kubeconfig.yaml"; export DEV_REGISTRY=-;'
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

# Initializers and other configs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH=$HOME/.activecampaign/bin:$PATH

# ac-platform init
eval $(ac-platform kube-init)

# Leaving this in case I want Jabba back for some reason, can be removed if I do not care
# about jabba anymore. -- 2020-01-08
#[ -s "/Users/ppeble/.jabba/jabba.sh" ] && source "/Users/ppeble/.jabba/jabba.sh"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/ppeble/.sdkman"
[[ -s "/Users/ppeble/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/ppeble/.sdkman/bin/sdkman-init.sh"
