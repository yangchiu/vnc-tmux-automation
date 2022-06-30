from behave import fixture
from behave import use_fixture
import libtmux


@fixture
def pane(context):
    server = libtmux.Server()
    session = server.find_where({"session_name": "session"})
    window = session.attached_window
    context.pane = window.attached_pane
    context.pane.send_keys('export KUBECONFIG=${HOME}/k3s.yaml')


def before_feature(context, feature):
    use_fixture(pane, context)
