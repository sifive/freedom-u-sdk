#!groovy

// pr-ci - run this on pull-requests

import groovy.json.JsonOutput
import groovy.json.JsonSlurper


// Global variables
// Groovy/Jenkins sandbox scoping rules are strange and functions defined in
// this file cannot reference variables declared at the top level, but they can
// reference classes and static class variables defined at the top level.
class G {
    // Set a common WCKEY for all slurm jobs launched by this
    // pipeline. This won't capture everything because some jobs still
    // run on the slurm agent and thus cannot be readily tracked.
    // The slurm account is set in the run_job function so it is
    // specific to the job being run.
    //
    // The 'mkg_' prefix is to differentiate jobs that
    // also use UUID in this same fashion.
    static String SLURM_WCKEY = 'fusdk_' + UUID.randomUUID().toString()

    // git repo info
    static String GITHUB_REPO = 'sifive/freedom-u-sdk'
    static String GIT_REMOTE = 'git@github.com:sifive/freedom-u-sdk.git'

    // NSF store for credentials
    static String SECRET_STORE = '/work/implementation/methodology-secret-store/api.json'

    // slack
    static String SLACK_CHANNEL = null
}

enum GitHubStatus implements Serializable {PENDING, FAILURE, SUCCESS}

// Groovy/Jenkins enums don't seem to be accessible through a 'load'
def enumGitHubStatusPending() {
  return GitHubStatus.PENDING
}

def sendGitHubStatus(GitHubStatus status, String commit, env) {
    def description
    def state
    switch (status) {
        case GitHubStatus.PENDING:
            description = 'Pending Jenkins build'
            state = 'pending'
            break;
        case GitHubStatus.FAILURE:
            description = 'Jenkins build failed'
            state = 'failure'
            break;
        case GitHubStatus.SUCCESS:
            description = 'Jenkins build succeeded'
            state = 'success'
            break;
        default:
            throw new Exception("Invalid status: ${status}")
    }
    def requestBody = JsonOutput.toJson([
        state: state,
        description: description,
        target_url: env.BUILD_URL,
        context: env.JOB_NAME,
    ])
    def requestURL = "https://api.github.com/repos/${G.GITHUB_REPO}/statuses/${commit}"
    def oauthToken = sh(returnStdout: true, script: "jq -r .github.oauth_token_id ${G.SECRET_STORE}")
    withCredentials([[
        $class: 'StringBinding',
        credentialsId: oauthToken,
        variable: 'GITHUB_OAUTH_TOKEN',
    ]]) {
        sh """curl --fail -H "Authorization: token \$GITHUB_OAUTH_TOKEN" -H 'Content-Type: application/json' -X POST '${requestURL}' -d '${requestBody}'"""
    }
}

def commitHash

ansiColor('xterm') {
  timestamps {

    result = 0

    stage('checkout') {
      node('freedom-u-sdk_pr_agent_small||tiny') {
        echo "Exploring memories..."
        commitHash = checkout(scm).GIT_COMMIT
        sendGitHubStatus(enumGitHubStatusPending(), commitHash, env)
      }
    }

    stage('basic-tests') {
      node('freedom-u-sdk_pr_agent_small') {

        def kebabName = "basic-tests".replaceAll(/ /, '-')
        def sshId = sh(returnStdout: true, script: "jq -r .github.ssh_id ${G.SECRET_STORE} | tr -d '\n'")
        ws("/scratch/jenkins/archived-builds/${env.JOB_NAME}-${kebabName}/${env.BUILD_ID}") {
          deleteDir()

          checkout([
              $class: 'GitSCM',
              branches: [[name: commitHash]],
              userRemoteConfigs: [[
                  credentialsId: sshId,
                  url: "${G.GIT_REMOTE}",
              ]],
          ])
          if (BASE_COMMIT != '') {
            sh "git checkout --detach && git merge ${BASE_COMMIT}"
          }

          //Modify/Add/Commands to Run
          sh returnStdout: true, script: 'echo $HOSTNAME'
          echo "hello WORLD!!"


          // install
//          timeout(time: 30, unit: 'MINUTES') {
//            result += sh returnStatus: true, script:  """
//              . /sifive/tools/Modules/init-chooser
//              module load ./env/default.module
//              ./bin/install
//            """
//          }
//
//          // lint
//          timeout(time: 5, unit: 'MINUTES') {
//            result += sh returnStatus: true, script:  """
//              . /sifive/tools/Modules/init-chooser
//              module load ./env/default.module
//              ./bin/tests/lint
//            """
//          }
//
//          // run tests
//          timeout(time: 300, unit: 'MINUTES') {
//            result += sh returnStatus: true, script:  """
//                . /sifive/tools/Modules/init-chooser
//                module load ./env/default.module
//                ./bin/limit_stdout nice ./bin/tests/run_tests
//            """
//          }

        } // ws
      } // node
    } // stage genHDLs


    stage('report') {
      node('freedom-u-sdk_pr_agent_small||tiny') {
        // TODO: extract results

        // Push result to Github
        if (result == 0) {
          resultStr = 'PASSED'
          resultCol = '#00FF00'
          sendGitHubStatus(GitHubStatus.SUCCESS, commitHash, env)
        } else {
          resultStr = 'FAILED'
          resultCol = '#FF0000'
          sendGitHubStatus(GitHubStatus.FAILURE, commitHash, env)

          // exit on fail
          error("${resultStr} with result ${result}")
        }

        // Send notice to slack on success
        slackSend channel: "${G.SLACK_CHANNEL}", color: resultCol, message: "${resultStr} on ${env.NODE_NAME}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"

      } // node
    } // stage

  } // timestamps
} // ansiColor
