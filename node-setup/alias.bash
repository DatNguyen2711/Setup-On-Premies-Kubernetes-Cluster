#!/bin/bash
echo "Adding kubectl aliases to ~/.bashrc..."

cat <<EOL >> ~/.bashrc

# Kubectl Aliases
alias k=kubectl

alias kg="k get"
alias kgp="kg po"
alias kgd="kg deploy"
alias kgn="kg nodes"
alias kgsvc="kg svc"
alias kging="kg ingress"
alias kgpv="kg pv"
alias kgpvc="kg pvc"
alias kgns="kg ns"
alias kgsec="kg secret"
alias kgrs="kg rs"
alias kgsts="kg sts"
alias kgiss="kg issuer"
alias kgc="kg challenge"

# Apply and Delete aliases
alias ka="k apply"
alias kdel="k delete"
alias kdelp="kdel po"
alias kdeld="kdel deploy"
alias kdelsvc="kdel svc"
alias kdeling="kdel ingress"
alias kdelpv="kdel pv"
alias kdelpvc="kdel pvc"
alias kdelns="kdel ns"
alias kdelsec="kdel secret"
alias kdelrs="kdel rs"
alias kdelsts="kdel sts"

# Describe aliases
alias kd="k describe"
alias kdp="kd po"
alias kdd="kd deploy"
alias kdsvc="kd svc"
alias kding="kd ingress"
alias kdpv="kd pv"
alias kdpvc="kd pvc"
alias kdns="kd ns"
alias kdsec="kd secret"
alias kdrs="kd rs"
alias kdsts="kd sts"
alias kdc="kd challenge"

# Config aliases
alias kgctx="k config get-contexts"
alias kcurctx="k config current-context"
alias kusectx="k config use-context"
alias kusens="k config set-context --current"

# Top aliases
alias kt="k top"
alias ktp="kt po"
alias ktn="kt nodes"

EOL


chmod +x alias.sh
./alias.sh
