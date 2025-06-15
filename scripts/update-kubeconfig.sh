sed "s|<PUBLIC_IP>|$PUBLIC_IP|g" kubeconfig-template.yaml > ~/.kube/config-ec2
