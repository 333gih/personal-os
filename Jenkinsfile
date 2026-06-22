// =============================================================================
// Jenkinsfile — Personal OS (ONE pipeline → API + Frontend + Postgres)
//
// Single job deploys BOTH services in one run:
//   • personal-os-api-app-{env}  (Go API, alias personal-os-api)
//   • personal-os-fe-app-{env}   (Next.js, alias personal-os-fe)
//   • personal-os-pg-{env}       (Postgres sidecar, alias personal-os-pg)
//
// Jenkins credentials (two secret files — fash core-service + portal-fe pattern):
//   env-personal-os-api-dev | env-personal-os-api-staging | env-personal-os-api-prod
//   env-personal-os-fe-dev  | env-personal-os-fe-staging  | env-personal-os-fe-prod
// Templates: backend/.env.prod, frontend/.env.prod
//
// Flow: Checkout → Test → Build API + FE → Deploy PG → Deploy API → wait healthy → Deploy FE → Health both
// =============================================================================

pipeline {

    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['prod', 'staging', 'dev'],
            description: 'Target deployment environment (default: prod)'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip tests — emergency hotfix only'
        )
        string(
            name: 'GIT_BRANCH',
            defaultValue: 'main',
            trim: true,
            description: 'Git branch to build and deploy (GitLab). Default: main'
        )
    }

    environment {
        GIT_REPO       = 'https://gitlab.com/personal-os1/personal-os.git'
        CREDENTIALS_ID = 'e8689c9a-5588-4725-b8cd-712ae345d8e1'

        REGISTRY         = 'docker.io'
        DOCKER_NAMESPACE = 'phuckhoa'
        API_IMAGE_NAME   = 'personal-os-api'
        FE_IMAGE_NAME    = 'personal-os-fe'

        TRAEFIK_NET     = 'traefik-public'
        SEAWEEDFS_NET   = 'seaweedfs-net'
        SLACK_CHANNEL   = '#ci-cd-alert'
        SLACK_ERROR_LOG = '#ci-cd-errors'

        DOCKER_BUILDKIT = '1'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
    }

    stages {

        stage('Notify Start') {
            steps {
                slackSend(
                    channel: env.SLACK_CHANNEL,
                    color: 'warning',
                    message: "🟡 *STARTED (personal-os API+FE):* `${env.JOB_NAME}` #${env.BUILD_NUMBER}\n" +
                             "Environment: *${params.ENVIRONMENT}* • Branch: *${params.GIT_BRANCH}*\n" +
                             "${env.BUILD_URL}"
                )
            }
        }

        stage('Checkout') {
            steps {
                // Deferred wipeout leaves root-owned backend/frontend from prior docker bind mounts.
                cleanWs(deleteDirs: true, disableDeferredWipeout: true)
                sh """#!/usr/bin/env bash
                    set -eo pipefail
                    ws="${env.WORKSPACE}"
                    purge_docker_mount_dirs() {
                        docker run --rm -v "\${ws}:/workspace" alpine \\
                            sh -c 'rm -rf /workspace/backend /workspace/frontend' || true
                    }
                    verify_source_tree() {
                        test -f backend/go.mod || { echo 'ERROR: backend/go.mod missing after checkout'; exit 2; }
                        test -f frontend/package.json || { echo 'ERROR: frontend/package.json missing after checkout'; exit 2; }
                        echo '=== backend (post-checkout) ==='
                        ls -la backend/ | head -20
                    }
                    purge_docker_mount_dirs
                """
                git(
                    branch: params.GIT_BRANCH,
                    url: env.GIT_REPO,
                    credentialsId: env.CREDENTIALS_ID
                )
                script {
                    env.SHORT_COMMIT = sh(
                        script: 'git rev-parse --short=8 HEAD',
                        returnStdout: true
                    ).trim()
                    // Always re-checkout backend/frontend: git skips paths blocked by root-owned empty dirs.
                    sh """#!/usr/bin/env bash
                        set -eo pipefail
                        ws="${env.WORKSPACE}"
                        purge_docker_mount_dirs() {
                            docker run --rm -v "\${ws}:/workspace" alpine \\
                                sh -c 'rm -rf /workspace/backend /workspace/frontend'
                        }
                        verify_source_tree() {
                            test -f backend/go.mod || { echo 'ERROR: backend/go.mod missing after checkout'; exit 2; }
                            test -f frontend/package.json || { echo 'ERROR: frontend/package.json missing after checkout'; exit 2; }
                            echo '=== backend (post-checkout) ==='
                            ls -la backend/ | head -20
                        }
                        purge_docker_mount_dirs
                        git checkout HEAD -- backend/ frontend/
                        verify_source_tree
                    """
                    echo "✅ Checked out ${params.GIT_BRANCH} @ ${env.SHORT_COMMIT}"
                }
            }
        }

        stage('Build & Test Backend') {
            when {
                expression { return !params.SKIP_TESTS }
            }
            steps {
                script {
                    // Jenkins-in-Docker: bind-mounting ${WORKSPACE} hits the host path, not the
                    // Jenkins container filesystem (checkout files exist only in the latter).
                    // Stream backend source via tar stdin instead of -v workspace.
                    sh 'docker volume create go-mod-cache-personal-os 2>/dev/null || true'
                    sh """#!/usr/bin/env bash
                        set -eo pipefail
                        test -f backend/go.mod || { echo 'ERROR: backend/go.mod missing in Jenkins workspace'; exit 2; }
                        tar -cC backend . | docker run --rm -i \\
                            -e CGO_ENABLED=0 \\
                            -e GO111MODULE=on \\
                            -v go-mod-cache-personal-os:/go/pkg/mod \\
                            -w /app \\
                            golang:1.24-bookworm \\
                            bash -ec 'set -e; mkdir -p /app; tar -xC /app; echo \"=== backend (in container) ===\"; ls -la; test -f go.mod; go mod download; go test ./... -count=1; go vet ./...'
                    """
                }
            }
            post {
                failure {
                    slackSend(
                        channel: env.SLACK_ERROR_LOG,
                        color: 'danger',
                        message: "❌ *personal-os TEST FAILED:* `${env.JOB_NAME}` #${env.BUILD_NUMBER}\n" +
                                 "${env.BUILD_URL}console"
                    )
                }
            }
        }

        stage('Build API & Frontend Images') {
            steps {
                script {
                    env.IMAGE_TAG        = "${params.ENVIRONMENT}-${env.BUILD_NUMBER}"
                    env.API_FULL_IMAGE   = "${env.REGISTRY}/${env.DOCKER_NAMESPACE}/${env.API_IMAGE_NAME}:${env.IMAGE_TAG}"
                    env.API_LATEST_IMAGE = "${env.REGISTRY}/${env.DOCKER_NAMESPACE}/${env.API_IMAGE_NAME}:${params.ENVIRONMENT}-latest"
                    env.FE_FULL_IMAGE    = "${env.REGISTRY}/${env.DOCKER_NAMESPACE}/${env.FE_IMAGE_NAME}:${env.IMAGE_TAG}"
                    env.FE_LATEST_IMAGE  = "${env.REGISTRY}/${env.DOCKER_NAMESPACE}/${env.FE_IMAGE_NAME}:${params.ENVIRONMENT}-latest"

                    // ── 1/2 API image (no env file at build — core-service pattern)
                    sh """
                        set -eo pipefail
                        echo "=== [1/2] Building API: ${env.API_FULL_IMAGE} ==="
                        docker build \\
                            --file backend/Dockerfile \\
                            --tag ${env.API_FULL_IMAGE} \\
                            --tag ${env.API_LATEST_IMAGE} \\
                            --label git.commit=${env.SHORT_COMMIT} \\
                            --label build.number=${env.BUILD_NUMBER} \\
                            --label environment=${params.ENVIRONMENT} \\
                            --label service=personal-os-api \\
                            backend
                    """

                    // ── 2/2 FE image (NEXT_PUBLIC_* from FE Jenkins secret — fash-portal-fe pattern)
                    withCredentials([file(
                        credentialsId: "env-personal-os-fe-${params.ENVIRONMENT}",
                        variable: 'FE_ENV_FILE'
                    )]) {
                        sh """#!/usr/bin/env bash
                            set -eo pipefail
                            FE_ENV_LF="${env.WORKSPACE}/.jenkins.fe.${env.BUILD_NUMBER}.env"
                            cleanup() { rm -f "\${FE_ENV_LF}" || true; }
                            trap cleanup EXIT
                            # Jenkins secret files edited on Windows often have CRLF — strip before source/build.
                            LC_ALL=C sed '1s/^\\xEF\\xBB\\xBF//' "\${FE_ENV_FILE}" | tr -d '\\r' > "\${FE_ENV_LF}"

                            echo "=== [2/2] Building FE: ${env.FE_FULL_IMAGE} (env-personal-os-fe-${params.ENVIRONMENT}) ==="
                            docker build \\
                                --file frontend/Dockerfile \\
                                --secret id=env_build,src="\${FE_ENV_LF}" \\
                                --tag ${env.FE_FULL_IMAGE} \\
                                --tag ${env.FE_LATEST_IMAGE} \\
                                --label git.commit=${env.SHORT_COMMIT} \\
                                --label build.number=${env.BUILD_NUMBER} \\
                                --label environment=${params.ENVIRONMENT} \\
                                --label service=personal-os-fe \\
                                frontend
                        """
                    }
                    echo "✅ Both images built (API + FE) tag ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Deploy API, Frontend & Postgres') {
            steps {
                script {
                    def pgContainer  = "personal-os-pg-${params.ENVIRONMENT}"
                    def apiContainer = "personal-os-api-app-${params.ENVIRONMENT}"
                    def feContainer  = "personal-os-fe-app-${params.ENVIRONMENT}"
                    def appNetwork   = "personal-os-net-${params.ENVIRONMENT}"
                    def pgVolume     = "personal-os-pgdata-${params.ENVIRONMENT}"

                    env.API_CONTAINER = apiContainer
                    env.FE_CONTAINER  = feContainer

                    sh """
                        for net in ${appNetwork} ${env.TRAEFIK_NET}; do
                            docker network inspect "\$net" >/dev/null 2>&1 || docker network create "\$net"
                        done
                        docker volume create ${pgVolume} 2>/dev/null || true
                    """

                    withCredentials([
                        file(
                            credentialsId: "env-personal-os-api-${params.ENVIRONMENT}",
                            variable: 'API_ENV_FILE'
                        ),
                        file(
                            credentialsId: "env-personal-os-fe-${params.ENVIRONMENT}",
                            variable: 'FE_ENV_FILE'
                        ),
                    ]) {
                        sh """#!/usr/bin/env bash
                            set -eo pipefail
                            API_ENV_LF="${env.WORKSPACE}/.jenkins.api.${env.BUILD_NUMBER}.env"
                            FE_ENV_LF="${env.WORKSPACE}/.jenkins.fe.${env.BUILD_NUMBER}.env"
                            cleanup() { rm -f "\${API_ENV_LF}" "\${FE_ENV_LF}" || true; }
                            trap cleanup EXIT
                            # Strip BOM/CRLF (Windows-edited Jenkins secrets break shell source and docker --env-file).
                            LC_ALL=C sed '1s/^\\xEF\\xBB\\xBF//' "\${API_ENV_FILE}" | tr -d '\\r' > "\${API_ENV_LF}"
                            LC_ALL=C sed '1s/^\\xEF\\xBB\\xBF//' "\${FE_ENV_FILE}" | tr -d '\\r' > "\${FE_ENV_LF}"

                            # Do not source env files — unquoted values with spaces (e.g. APP_DESCRIPTION)
                            # break bash; docker --env-file handles them correctly.
                            env_get() {
                                local key="\$1" file="\$2" val=""
                                val=\$(grep -E "^\${key}=" "\$file" 2>/dev/null | head -1 | cut -d= -f2- || true)
                                case "\$val" in
                                    \"*\") val="\${val#\\"}"; val="\${val%\\"}" ;;
                                    \'*\') val="\${val#\\'}"; val="\${val%\\'}" ;;
                                esac
                                printf '%s' "\$val"
                            }

                            verify_pg_tcp_auth() {
                                docker run --rm --network ${appNetwork} \\
                                    -e PGPASSWORD="\${POSTGRES_DATABASE_PASSWORD}" \\
                                    pgvector/pgvector:pg17 \\
                                    psql -h personal-os-pg -p 5432 -U "\${POSTGRES_DATABASE_USER}" -d "\${POSTGRES_DATABASE_NAME}" -c 'SELECT 1' >/dev/null 2>&1
                            }

                            # Kong upstream network — often iot-public-net-dev while ENVIRONMENT=prod
                            IOT_PUBLIC_NET="\$(env_get IOT_PUBLIC_NET "\${API_ENV_LF}")"
                            if [ -z "\${IOT_PUBLIC_NET}" ]; then
                                IOT_PUBLIC_NET="iot-public-net-${params.ENVIRONMENT}"
                            fi
                            echo "[INFO] Kong upstream network (IOT_PUBLIC_NET)=\${IOT_PUBLIC_NET}"
                            docker network inspect "\${IOT_PUBLIC_NET}" >/dev/null 2>&1 || docker network create "\${IOT_PUBLIC_NET}"
                            env_get_first() {
                                local file="\$1"; shift
                                local key val
                                for key in "\$@"; do
                                    val="\$(env_get "\$key" "\$file")"
                                    if [ -n "\$val" ]; then
                                        printf '%s' "\$val"
                                        return 0
                                    fi
                                done
                                return 0
                            }

                            echo "[INFO] Loading deploy env files..."
                            POSTGRES_DATABASE_USER="\$(env_get_first "\${API_ENV_LF}" POSTGRES_DATABASE_USER POSTGRES_USER)"
                            POSTGRES_DATABASE_PASSWORD="\$(env_get_first "\${API_ENV_LF}" POSTGRES_DATABASE_PASSWORD POSTGRES_PASSWORD)"
                            POSTGRES_DATABASE_NAME="\$(env_get_first "\${API_ENV_LF}" POSTGRES_DATABASE_NAME POSTGRES_DB)"
                            if [ -z "\${POSTGRES_DATABASE_USER}" ]; then
                                echo '[ERROR] POSTGRES_DATABASE_USER (or POSTGRES_USER) missing in API env file'
                                exit 1
                            fi
                            if [ -z "\${POSTGRES_DATABASE_PASSWORD}" ]; then
                                echo '[ERROR] POSTGRES_DATABASE_PASSWORD (or POSTGRES_PASSWORD) missing in API env file'
                                exit 1
                            fi
                            if [ -z "\${POSTGRES_DATABASE_NAME}" ]; then
                                echo '[ERROR] POSTGRES_DATABASE_NAME (or POSTGRES_DB) missing in API env file'
                                exit 1
                            fi
                            KAFKA_BROKER="\$(env_get KAFKA_BROKER "\${API_ENV_LF}")"
                            KAFKA_BROKERS="\$(env_get KAFKA_BROKERS "\${API_ENV_LF}")"

                            echo "=== Deploying personal-os (API + FE) env=${params.ENVIRONMENT} ==="
                            echo "    API credential: env-personal-os-api-${params.ENVIRONMENT}"
                            echo "    FE  credential: env-personal-os-fe-${params.ENVIRONMENT}"
                            echo "    API image: ${env.API_FULL_IMAGE}"
                            echo "    FE  image: ${env.FE_FULL_IMAGE}"
                            echo "    FE  URL:   \$(grep -E '^NEXT_PUBLIC_SITE_URL=' "\${FE_ENV_LF}" | cut -d= -f2- || echo '<unset>')"
                            echo "    API URL:   \$(grep -E '^NEXT_PUBLIC_API_URL=' "\${FE_ENV_LF}" | cut -d= -f2- || echo '<unset>')"

                            # ── Postgres (once)
                            if ! docker ps --format '{{.Names}}' | grep -Eq "^${pgContainer}\$"; then
                                docker rm -f ${pgContainer} 2>/dev/null || true
                                pgInitVol="personal-os-pg-init-${params.ENVIRONMENT}"
                                docker volume create "\${pgInitVol}" 2>/dev/null || true
                                # Stream migration SQL (avoid WORKSPACE bind-mount — Jenkins-in-Docker).
                                tar -cC backend/migrations 001_initial_schema.sql | docker run --rm -i -v "\${pgInitVol}:/initdb" alpine \\
                                    sh -c 'tar -xC /initdb && mv /initdb/001_initial_schema.sql /initdb/001_schema.sql'
                                echo "[INFO] [1/3] Starting PostgreSQL: ${pgContainer}"
                                docker run -d \\
                                    --name ${pgContainer} \\
                                    --network ${appNetwork} \\
                                    --network-alias personal-os-pg \\
                                    --restart unless-stopped \\
                                    -e POSTGRES_USER="\${POSTGRES_DATABASE_USER}" \\
                                    -e POSTGRES_PASSWORD="\${POSTGRES_DATABASE_PASSWORD}" \\
                                    -e POSTGRES_DB="\${POSTGRES_DATABASE_NAME}" \\
                                    -v ${pgVolume}:/var/lib/postgresql/data \\
                                    -v "\${pgInitVol}:/docker-entrypoint-initdb.d:ro" \\
                                    pgvector/pgvector:pg17

                                for i in \$(seq 1 30); do
                                    docker exec ${pgContainer} pg_isready -U "\${POSTGRES_DATABASE_USER}" >/dev/null 2>&1 && break
                                    [ \$i -eq 30 ] && echo "[ERROR] PostgreSQL timeout" && exit 1
                                    sleep 2
                                done
                                echo "[INFO] PostgreSQL ready ✅"
                            else
                                echo "[INFO] PostgreSQL already running: ${pgContainer}"
                            fi

                            if ! verify_pg_tcp_auth; then
                                echo '[ERROR] PostgreSQL TCP auth failed for API credentials.'
                                echo '[HINT] PG password is set only on first volume init. Either:'
                                echo '       1) Set POSTGRES_DATABASE_PASSWORD in env-personal-os-api-prod to the ORIGINAL password, or'
                                echo '       2) Reset volume (DATA LOSS): docker rm -f ${pgContainer} && docker volume rm ${pgVolume}'
                                echo '[HINT] Passwords with $ must be quoted in the env file: POSTGRES_DATABASE_PASSWORD="\$yourpass"'
                                exit 1
                            fi
                            echo "[INFO] PostgreSQL TCP auth OK for API user ✅"

                            # Idempotent SQL migrations (safe on every deploy).
                            for mig in 003_storage_key_prefix.sql 004_fix_users_email_constraint.sql 005_reading_progress.sql 006_reading_progress_latest_per_story.sql 007_ai_schema.sql 008_work_career_data.sql 009_work_design_cv.sql 010_work_career_all.sql 011_work_career_assign_user.sql 012_career_owner_functions.sql 013_fpt_architecture_layers.sql 014_cv_system.sql 015_job_opportunities.sql 016_cv_template_v2.sql 017_job_search_preferences.sql 018_cv_pdf_v5.sql 019_fash_startup_seed.sql 020_learning_dsa_english_interview.sql 021_learning_schedule_notifications.sql 022_dsa_mastery_daily_program.sql 023_cv_horserace_v6.sql; do
                                if [ -f "backend/migrations/\${mig}" ]; then
                                    echo "[INFO] Applying migration \${mig}..."
                                    cat "backend/migrations/\${mig}" | docker exec -i ${pgContainer} \\
                                        psql -v ON_ERROR_STOP=1 -U "\${POSTGRES_DATABASE_USER}" -d "\${POSTGRES_DATABASE_NAME}"
                                fi
                            done

                            # ── [2/3] API service
                            docker rm -f ${apiContainer} 2>/dev/null || true
                            echo "[INFO] [2/3] Starting API: ${apiContainer}"
                            docker create \\
                                --name ${apiContainer} \\
                                --network ${appNetwork} \\
                                --network-alias personal-os-api \\
                                --restart unless-stopped \\
                                --env-file "\${API_ENV_LF}" \\
                                --expose 8080 \\
                                --label service=personal-os-api \\
                                --label environment=${params.ENVIRONMENT} \\
                                ${env.API_FULL_IMAGE}

                            # Kong resolves PERSONAL_OS_API_HOST=personal-os-api:8080 on IOT_PUBLIC_NET.
                            # Must match fash-api-gateway's network (e.g. dev gateway → iot-public-net-dev).
                            if ! docker network connect --alias personal-os-api "\${IOT_PUBLIC_NET}" ${apiContainer} 2>/dev/null; then
                                echo "[INFO] API already on \${IOT_PUBLIC_NET} (checking alias personal-os-api)..."
                            fi
                            if docker network inspect ${env.SEAWEEDFS_NET} >/dev/null 2>&1; then
                                docker network connect ${env.SEAWEEDFS_NET} ${apiContainer} || true
                            else
                                echo "[WARN] Docker network ${env.SEAWEEDFS_NET} not found — S3/SeaweedFS may be unreachable"
                            fi
                            if [ -n "\${KAFKA_BROKER:-}" ] || [ -n "\${KAFKA_BROKERS:-}" ]; then
                                docker network inspect marketplace_obs >/dev/null 2>&1 || docker network create marketplace_obs
                                docker network connect marketplace_obs ${apiContainer} || true
                            fi
                            docker start ${apiContainer}

                            # Wait for API before FE (both services must be paired)
                            echo "[INFO] Waiting for API /health before deploying FE..."
                            API_OK=0
                            for i in \$(seq 1 24); do
                                if docker exec ${apiContainer} wget -qO- http://127.0.0.1:8080/health >/dev/null 2>&1; then
                                    echo "[INFO] API /health OK ✅"
                                    API_OK=1
                                    break
                                fi
                                STATUS=\$(docker inspect --format='{{.State.Status}}' ${apiContainer} 2>/dev/null || echo "missing")
                                if [ "\$STATUS" != "running" ]; then
                                    echo "[ERROR] API container not running (status=\$STATUS)"
                                    docker logs ${apiContainer} --tail 80
                                    exit 1
                                fi
                                sleep 5
                            done
                            if [ "\$API_OK" -ne 1 ]; then
                                echo "[ERROR] API failed health check — aborting FE deploy"
                                docker logs ${apiContainer} --tail 80
                                exit 1
                            fi

                            echo "[INFO] Verifying Kong upstream DNS on \${IOT_PUBLIC_NET} (personal-os-api:8080)..."
                            UPSTREAM_OK=0
                            for i in \$(seq 1 12); do
                                if docker run --rm --network "\${IOT_PUBLIC_NET}" curlimages/curl:8.5.0 -sf http://personal-os-api:8080/health >/dev/null 2>&1; then
                                    echo "[INFO] Kong upstream reachable on \${IOT_PUBLIC_NET} ✅"
                                    UPSTREAM_OK=1
                                    break
                                fi
                                sleep 2
                            done
                            if [ "\$UPSTREAM_OK" -ne 1 ]; then
                                echo "[ERROR] personal-os-api not reachable on \${IOT_PUBLIC_NET} — Kong will return 503 ring-balancer"
                                echo "[HINT] Set IOT_PUBLIC_NET in env-personal-os-api-${params.ENVIRONMENT} to the network fash-api-gateway uses"
                                echo "[HINT] docker network connect --alias personal-os-api \${IOT_PUBLIC_NET} ${apiContainer}"
                                docker logs ${apiContainer} --tail 40
                                exit 1
                            fi

                            # ── [3/3] Frontend service
                            docker rm -f ${feContainer} 2>/dev/null || true
                            echo "[INFO] [3/3] Starting FE: ${feContainer}"
                            docker run -d \\
                                --name ${feContainer} \\
                                --network ${appNetwork} \\
                                --network-alias personal-os-fe \\
                                --restart unless-stopped \\
                                --env-file "\${FE_ENV_LF}" \\
                                --expose 3000 \\
                                --label service=personal-os-fe \\
                                --label environment=${params.ENVIRONMENT} \\
                                ${env.FE_FULL_IMAGE}

                            docker network connect ${env.TRAEFIK_NET} ${feContainer} || true

                            echo "=== Deploy complete: API + FE running ==="
                            docker ps --filter name=personal-os- \\
                                --format 'table {{.Names}}\\t{{.Status}}\\t{{.Label "service"}}'
                        """
                    }

                    sh """
                        docker images ${env.DOCKER_NAMESPACE}/${env.API_IMAGE_NAME} \\
                            --format '{{.Tag}} {{.ID}}' | grep "^${params.ENVIRONMENT}-" | \\
                            sort -rV | tail -n +4 | awk '{print \$2}' | xargs -r docker rmi -f 2>/dev/null || true
                        docker images ${env.DOCKER_NAMESPACE}/${env.FE_IMAGE_NAME} \\
                            --format '{{.Tag}} {{.ID}}' | grep "^${params.ENVIRONMENT}-" | \\
                            sort -rV | tail -n +4 | awk '{print \$2}' | xargs -r docker rmi -f 2>/dev/null || true
                    """
                }
            }
        }

        stage('Health Check API & Frontend') {
            steps {
                script {
                    sh """
                        echo "[INFO] Final health: API (${env.API_CONTAINER})"
                        for i in \$(seq 1 6); do
                            docker exec ${env.API_CONTAINER} wget -qO- http://127.0.0.1:8080/health && break
                            [ \$i -eq 6 ] && exit 1
                            sleep 3
                        done

                        echo "[INFO] Final health: FE (${env.FE_CONTAINER})"
                        for i in \$(seq 1 6); do
                            docker exec ${env.FE_CONTAINER} wget -qO- http://127.0.0.1:3000/login >/dev/null 2>&1 && break
                            [ \$i -eq 6 ] && docker logs ${env.FE_CONTAINER} --tail 50 && exit 1
                            sleep 3
                        done

                        echo "✅ personal-os API + FE both healthy"
                        docker ps --filter name=personal-os- \\
                            --format 'table {{.Names}}\\t{{.Status}}\\t{{.Label "service"}}'
                    """
                }
            }
        }
    }

    post {
        success {
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'good',
                message: "✅ *personal-os API+FE SUCCESS:* `${env.JOB_NAME}` #${env.BUILD_NUMBER}\n" +
                         "Environment: *${params.ENVIRONMENT}* • Branch: *${params.GIT_BRANCH}*\n" +
                         "API: `${env.API_FULL_IMAGE}` → `${env.API_CONTAINER}`\n" +
                         "FE: `${env.FE_FULL_IMAGE}` → `${env.FE_CONTAINER}`\n" +
                         "${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'danger',
                message: "❌ *personal-os API+FE FAILED:* `${env.JOB_NAME}` #${env.BUILD_NUMBER}\n" +
                         "Check API: `${env.API_CONTAINER}` FE: `${env.FE_CONTAINER}`\n" +
                         "${env.BUILD_URL}console"
            )
        }
        always {
            sh 'docker image prune -f --filter "dangling=true" || true'
        }
    }
}
