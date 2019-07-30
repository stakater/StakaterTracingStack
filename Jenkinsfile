#!/usr/bin/env groovy
@Library('github.com/stakater/stakater-pipeline-library@v2.14.0') _

def utils = new io.fabric8.Utils()

String installTarget = "install"
String dryRunTarget = "install-dry-run"

timeout(time: 20, unit: 'MINUTES') {
    timestamps {
        toolsNode(toolsImage: 'stakater/pipeline-tools:v2.0.4') {
            container (name: "tools") {
                stage('Install') {
                    try {
                        checkout scm
                        String selectedTarget

                        // if master
                        if (utils.isCD()) {
                            selectedTarget = installTarget
                        } else {
                            selectedTarget = dryRunTarget
                        }

                        executeMakeTargets {
                            target = selectedTarget
                            FOLDER_NAME = "manifests"
                            NAMESPACE= "tracing"
                        }

                    } catch (err) {
                        echo "Error: ${err}"
                        throw err
                    }
                }
            }
        }
    }
}
