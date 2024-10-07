#!/usr/bin/env python3
import sys
import os
import subprocess

print(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))

sys.path.append(
    os.path.join(
        os.path.dirname(os.path.dirname(os.path.realpath(__file__))),
        "lib"
    )
)

#sys.path.append("../lib")

import logging

logging.basicConfig(level=logging.NOTSET)
# Logger
logger = logging.getLogger(__name__)

def install_dependencies():
    python_requirements = [
        "packaging==21.3",
        "dataclasses==0.8"
    ]

    # Update the apt cache
    logger.info("Updating packages...")
    subprocess.check_call(["sudo", "apt-get", "update"])
    
    # Make sure Python3 + PIP are available
    if not os.path.exists("/usr/bin/python3") or not os.path.exists("/usr/bin/pip3"):
        # This is needed when running as a k8s charm, as the ubuntu:latest
        # image doesn't include either package.
        # Install the Python3 package
        logger.info("Installing python3 and pip packages...")
        subprocess.check_call(
                                ["sudo", "apt-get", "install", 
                                "-y", "python3", "python3-pip"]
                            )
        logger.info("Successfully installed python3 and pip packages!")

    # Install the build dependencies for our requirements (paramiko)
    logger.info("Installing libffi-dev and libssl-dev...")
    subprocess.check_call(
                            ["sudo", "apt-get", "install", 
                            "-y", "libffi-dev", "libssl-dev"]
                        )

    if len(python_requirements) > 0:
        logger.info("Installing python3 modules...")
        subprocess.check_call(
                                ["sudo", "python3", "-m", "pip", 
                                "install", "--upgrade", "pip"]
                            )        
        subprocess.check_call(
                                ["sudo", "python3", "-m", "pip", "install"] 
                                    + python_requirements
                            )
        logger.info("Successfully installed python3 modules!")

# start by installing all the required dependencies
try: 
    logger.info("Importing SSHProxyCharm...")
    from charms.osm.sshproxy import SSHProxyCharm
    logger.info("SSHProxyCharm successfully imported!")

except:
    logger.info("Entered except - installing dependencies...")
    install_dependencies()
    logger.info("Dependencies successfully installed!")

logger.info("Importing ops...")
from ops.main import main
from ops.charm import ActionEvent
logger.info("Ops successfully imported!")

from ops.model import (
    ActiveStatus,
    MaintenanceStatus,
    BlockedStatus,
    WaitingStatus,
    ModelError,
)

logger.info("Final - Importing SSHProxyCharm...")
from charms.osm.sshproxy import SSHProxyCharm
logger.info("Final - SSHProxyCharm successfully imported!")


class NetwokSliceProfileSelectorCharm(SSHProxyCharm):
    def __init__(self, framework):
        super().__init__(framework)

        # Listen to charm events
        self.framework.observe(self.on.config_changed, self.on_config_changed)
        self.framework.observe(self.on.install, self.on_install)
        self.framework.observe(self.on.start, self.on_start)
        # self.framework.observe(self.on.upgrade_charm, self.on_upgrade_charm)

        # Listen to the profile action event
        self.framework.observe(self.on.configure_remote_action, 
                                self.configure_remote)
        self.framework.observe(self.on.start_service_action, self.start_service)

        # Custom actions
        self.framework.observe(
                                self.on.change_network_slice_profile_action, 
                                self.on_change_network_slice_profile
                            )

        # OSM actions (primitives)
        self.framework.observe(self.on.start_action, self.on_start_action)
        self.framework.observe(self.on.stop_action, self.on_stop_action)
        self.framework.observe(self.on.restart_action, self.on_restart_action)
        self.framework.observe(self.on.reboot_action, self.on_reboot_action)
        self.framework.observe(self.on.upgrade_action, self.on_upgrade_action)

    def on_config_changed(self, event):
        """Handle changes in configuration"""
        super().on_config_changed(event)

    def on_install(self, event):
        """Called when the charm is being installed"""
        super().on_install(event)

    def on_start(self, event):
        """Called when the charm is being started"""
        super().on_start(event)

    def configure_remote(self, event):
        """Configure remote action."""

        if self.model.unit.is_leader():
            stderr = None
            try:
                mgmt_ip = self.model.config["ssh-hostname"]
                destination_ip = event.params["destination_ip"]
                cmd = "vnfcli set license {} server {}".format(
                    mgmt_ip,
                    destination_ip
                )
                proxy = self.get_ssh_proxy()
                stdout, stderr = proxy.run(cmd)
                logger.info({"output": stdout})
            except Exception as e:
                logger.error("Action failed {}. Stderr: {}".format(e, stderr))
        else:
            logger.error("Unit is not leader")

    def start_service(self, event):
        """Start service action."""

        if self.model.unit.is_leader():
            stderr = None
            try:
                cmd = "sudo service vnfoper start"
                proxy = self.get_ssh_proxy()
                stdout, stderr = proxy.run(cmd)
                logger.info({"output": stdout})
            except Exception as e:
                logger.error("Action failed {}. Stderr: {}".format(e, stderr))
        else:
            logger.error("Unit is not loader")

    ###############
    # OSM methods #
    ###############
    def on_start_action(self, event):
        """Start the VNF service on the VM."""
        pass

    def on_stop_action(self, event):
        """Stop the VNF service on the VM."""
        pass

    def on_restart_action(self, event):
        """Restart the VNF service on the VM."""
        pass

    def on_reboot_action(self, event):
        """Reboot the VM."""
        if self.unit.is_leader():
            pass

    def on_upgrade_action(self, event):
        """Upgrade the VNF service on the VM."""
        pass

    ##########################
    #     Custom Actions     #
    ##########################

    def on_change_network_slice_profile(self, event):
        logger.info("Entered on_change_network_slice_profile method")
        logger.info(f"event.params['profile']: {event.params['profile']}")
        self._change_network_slice_profile(event)

    ##########################
    #        Functions       #
    ##########################

    def _change_network_slice_profile(self, event):
        # Extract profile from the event parameters
        # (fallsback to default if not provided)
        logger.info("Entered _change_network_slice_profile method")
        logger.info("Getting event params...")

        logger.info(f"event: {event}")
        logger.info(f"event.params['profile']: {event.params['profile']}")
        

        if event.params['profile']:
            profile = event.params['profile']
            
        logger.info("Got event params!")

        self.unit.status = MaintenanceStatus(f"Enforcing the Network Slice Profile...")
        try:
            proxy = self.get_ssh_proxy()

            result, error = proxy.run(f"wget https://raw.githubusercontent.com/eduardosantoshf/network-slice-profile-selector-vnf/refs/heads/main/aux/enforce_slice_profile.sh")
            proxy.run("chmod +xr enforce_slice_profile.sh")
            proxy.run(f"echo \"Start: $(date +%s%3N)\" >> timestamps.txt && ./enforce_slice_profile.sh {profile} && echo \"End: $(date +%s%3N)\" >> timestamps.txt")
            logger.info({"output": result, "errors": error})

            self.unit.status = MaintenanceStatus("Successfully Enforced the Network Slice Profile: {profile}")
        except Exception as e:
            logger.error(
                        "[Couldn't Pull File {profile}] \
                            Action failed {}. Stderr: {}"
                                .format(e, error)
                    )
            self.unit.status = BlockedStatus("Couldn't Enforce the Network Slice Profile: {profile}")
            return False

        return True


if __name__ == "__main__":
    main(NetwokSliceProfileSelectorCharm)