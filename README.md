# Deploy the Blue Bank Demo

This demo assumes:

* you have an online remote repository (github / bitbucket etc.)
* you have a local git repo
* and a cloud server/ end point
  * you have Jenkins, Ansible & the necessary playbooks
  * you have necessary users & permissions created on the endpoints
  * you have Nginx+ set-up ready to be deployed to
  

# 1 - On your Jenkins Machine

*This is the Jenkins Master Node - Deployments to other Nodes (Gateways) will be triggered from here*

# 2 - On your end-point - Gateway / Node

*You have Nginx Plus installed and running. SSH enabled for it to accept remote push from Jenkins Master*

## Troubleshooting

    java installed
    user created with sudo previliges & access to remotely execute via visudo
    sshd config enabled to enable password 'yes'
## Bearer Token

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJhZG1pbiI6dHJ1ZX0.81hUKh-nDlFM5FD400i4J99EHYWENMHqQLpY_qEmUEM
