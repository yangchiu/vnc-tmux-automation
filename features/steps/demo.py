from behave import *
import time


def exec_cmd(context, cmd):
    context.pane.send_keys(cmd)
    time.sleep(8)


def get_cmd_return(context):
    ret = '\n'.join(context.pane.cmd('capture-pane', '-p').stdout).split(':~$')[-2]
    print(ret)
    return ret


@given('longhorn installed')
def longhorn_installed(context):
    cmd = "kubectl get pods -n longhorn-system --no-headers | awk '{print $3}' | grep -v Running"
    exec_cmd(context, cmd)
    if cmd not in get_cmd_return(context):
        raise RuntimeError('Longhorn not installed')
    cmd = "kubectl port-forward services/longhorn-frontend 8080:http -n longhorn-system &"
    exec_cmd(context, cmd)
    if '[1]' not in get_cmd_return(context):
        raise RuntimeError('fail to forward port')


@then('create volume')
def create_volume(context):
    cmd = "curl --header \"Content-Type: application/json\" --request POST " \
          "--data '{\"size\": \"1073741824\", \"name\": \"test-1\"}' http://localhost:8080/v1/volumes?action=create"
    exec_cmd(context, cmd)
    if '"accessMode":"rwo"' not in get_cmd_return(context):
        raise RuntimeError('expect volume created')


@then('attach volume')
def attach_volume(context):
    cmd = "curl --header \"Content-Type: application/json\" --request POST " \
          "--data '{\"hostId\": \"ip-10-0-1-213\", \"disableFrontend\": false}' " \
          "http://localhost:8080/v1/volumes/test-1?action=attach"
    exec_cmd(context, cmd)
    if '"accessMode":"rwo"' not in get_cmd_return(context):
        raise RuntimeError('expect volume attached')


@then('ssh into node')
def ssh_into_node(context):
    cmd = "ssh -o StrictHostKeyChecking=no ubuntu@ec2-3-85-142-48.compute-1.amazonaws.com"
    exec_cmd(context, cmd)
    time.sleep(5)
    if 'ubuntu@ip-10-0-1-213' not in get_cmd_return(context):
        raise RuntimeError('expect ssh')


@then('write random data')
def write_random_data(context):
    cmd = "sudo dd if=/dev/urandom of=/dev/longhorn/test-1 bs=1M count=64"
    exec_cmd(context, cmd)
    if 'copied' not in get_cmd_return(context):
        raise RuntimeError('expect dd executed')


@then('exit ssh')
def exit_ssh(context):
    cmd = "exit"
    exec_cmd(context, cmd)


@then('expect volume actual size')
def expect_volume_actual_size(context):
    cmd = "curl --header \"Content-Type: application/json\" --request GET " \
          "http://localhost:8080/v1/volumes/test-1"
    exec_cmd(context, cmd)
    if '"state":"attached"' not in get_cmd_return(context):
        raise RuntimeError('expect volume actual size')


@then('stop node')
def stop_node(context):
    cmd = "aws ec2 stop-instances --instance-ids i-0121d0c92d30f8888"
    exec_cmd(context, cmd)


@then('expect volume robustness unknown')
def expect_volume_robustness_unknown(context):
    cmd = "curl --header \"Content-Type: application/json\" --request GET " \
          "http://localhost:8080/v1/volumes/test-1"
    exec_cmd(context, cmd)
    if '"accessMode":"rwo"' not in get_cmd_return(context):
        raise RuntimeError('expect volume actual size')
