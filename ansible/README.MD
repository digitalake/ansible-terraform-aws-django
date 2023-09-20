

ansible-playbook \
    -i inventory \
    --ssh-extra-args='-F jumpconf' \
    -e "DB_NAME=<value>" \
    -e " DB_USER=<value>" \
    -e "DB_PASSWORD=<value>" \
    prepare-db.yml \

ansible-playbook \
	-i inventory \
	--ssh-extra-args='-F jumpconf' \
	-e "DB_NAME=<value>" \
	-e "DB_USER=<value>" \
	-e "DB_PASSWORD=<value>" \
	-e "CI_REGISTRY_USER=<value>" \
	-e "CI_REGISTRY_PASSWORD=<value>" \
	deploy-application.yml -vvv \