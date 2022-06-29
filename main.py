import libtmux


def get_default_pane():
    server = libtmux.Server()
    session = server.find_where({"session_name": "session"})
    window = session.attached_window
    pane = window.attached_pane
    return pane


def set_kubeconfig(pane):
    pane.send_keys('export KUBECONFIG=${HOME}/k3s.yaml')


def run_cmd(pane, cmd):
    pane.send_keys(cmd)




if __name__ == '__main__':


    fout = open('pythontest', 'wb')
    child = pexpect.spawn('/bin/bash', logfile=fout, echo=True)
    child.sendline('ls')
    #child.readlines()


    #print(process.expect(pexpect.EOF))

