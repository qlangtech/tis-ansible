# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an Ansible automation repository for deploying and managing TIS (大数据中台) - a distributed data platform. TIS is a comprehensive data infrastructure that integrates multiple big data components including Hadoop HDFS/YARN, Spark, Zookeeper, Hive, Solr, and custom TIS applications (console, assemble, index-builder).

## Common Commands

### Deployment Commands

**Deploy from compiled source (full installation):**
```bash
ansible-playbook ./deploy-tis-by-compile.yml --tags initos,zk,hadoop,spark,pkg,pkg-plugin,ng-tis,tjs,assemble,indexbuilder,solr --skip-tags=deploy -i ./inventory/hosts
```

**Deploy from release artifacts:**
```bash
ansible-playbook ./deploy-tis-by-release.yml --tags initos,zk,hadoop,spark,tjs,assemble,indexbuilder,solr -i ./inventory/hosts
```

**Deploy to repository (publishing artifacts):**
```bash
ansible-playbook ./deploy-tis-by-compile.yml --tags pkg,pkg-plugin,tis-sqlserver-plugin,tis-paimon-plugin,pkg-plugin-vip,ng-tis,uber,uber-docker,datax-docker,flink-docker,update-center,deploy,deploy-tis-repo -i ./inventory/hosts
```

### Compilation Commands

**Compile specific components:**
```bash
# DataX docker image
ansible-playbook ./deploy-tis-by-compile.yml --tags pkg,datax-docker --skip-tags=deploy -i ./inventory/hosts

# Uber package
ansible-playbook ./deploy-tis-by-compile.yml --tags pkg,pkg-plugin,ng-tis,uber --skip-tags=deploy -i ./inventory/hosts
```

### Service Management

**Start all services:**
```bash
ansible-playbook ./start.yml
```

**Stop all services:**
```bash
ansible-playbook ./stop.yml
```

**Restart YARN and Spark ThriftServer only:**
```bash
ansible-playbook ./stop-yarn-and-thriftserver.yml
ansible-playbook ./start-yarn-and-thriftserver.yml
```

**Restart TIS components on specific host groups:**
```bash
ansible solr -i ./inventory/hosts -m service --become -a "name=spring-boot state=restarted"
```

### Testing and Development

**Remote install Java on specific host:**
```bash
ansible all -i "ip," -m include_role -a "name=jdk" -e "@vars.yml" -u root
```

**SSH key distribution:**
```bash
ansible solr,hadoop-hdfs-datanode -m authorized_key -a "user=root key='{{ lookup('file', '/root/.ssh/id_rsa.pub') }}'" -k
```

**Test connectivity:**
```bash
ansible solr,hadoop-hdfs-datanode -m ping
```

## Architecture

### Component Structure

The platform is organized into several logical layers deployed across different host groups:

**Storage Layer:**
- **HDFS**: Distributed file system (namenode + datanodes)
- **Zookeeper**: Coordination service for distributed systems

**Compute Layer:**
- **YARN**: Resource manager and node managers for job scheduling
- **Spark**: Distributed computing engine (optional, can include TiSpark for TiDB integration)
- **Hive**: Data warehouse with metastore and HiveServer2

**Search Layer:**
- **Solr**: Full-text search engine deployed on dedicated solr nodes

**TIS Application Layer:**
- **tjs (TIS Console)**: Web UI and control center, runs on port 8080
- **tis-assemble**: Assembly and orchestration service
- **index-builder**: Full-text index building service deployed on YARN nodes
- **ng-tis**: Angular-based frontend application

**Containerized Components:**
- **tis-uber**: Standalone all-in-one Docker package with embedded Derby database
- **tis-datax-executor**: PowerJob-based DataX execution container
- **flink**: Stream processing (version 1.20.1 with TIS extensions)

### Deployment Models

**Compilation-based Deployment (`deploy-tis-by-compile.yml`):**
- Clones source code from Git repositories (GitHub/Gitee)
- Compiles using Maven with configurable profiles (e.g., `-Pcdh`, `-Paliyun-emr`)
- Generates multiple artifacts with classifier variants for different Hadoop distributions
- Creates Docker images and publishes to registry
- Places compiled artifacts in `/tmp/release/tis/` and `/tmp/release/tis-plugin/`

**Release-based Deployment (`deploy-tis-by-release.yml`):**
- Downloads pre-built artifacts from OSS (`tis_release_dir`)
- Skips compilation, directly installs components
- Faster deployment for production environments

### Configuration Management

**Primary Configuration Files:**
- `vars.yml`: Main configuration (version, memory, install flags, repository URLs)
- `vars-deploy.yml`: Deployment-specific variables (not in repo)
- `inventory/hosts`: Host inventory with groups and connection details

**Critical vars.yml Settings:**
- `tis_pkg_version`: Current version being deployed (e.g., "4.3.0")
- `yarn_nodemanager_resource_memorymb`: YARN memory allocation (e.g., 18432 for 18GB)
- `need_install_*`: Feature flags for optional components (hadoop, spark, zookeeper, etc.)
- `src_root`: Source code location (`/opt/data/tiscode`)
- `tis_release_dir`: Build artifact output directory (`/tmp/release`)

**Repository Configuration:**
- `release_repository`: OSS URL for downloading releases (`http://tis-release.oss-cn-beijing.aliyuncs.com`)
- `tis_mvn_repository`: Maven artifact repository (`http://mvn-repo.oss-cn-hangzhou.aliyuncs.com/release`)

### Service Startup Order

The start sequence in `start.yml` is critical:
1. Zookeeper
2. HDFS (start-dfs.sh on namenode)
3. YARN (start-yarn.sh on resource manager)
4. Hive Metastore and HiveServer2 (optional)
5. Spark ThriftServer on YARN (optional, cluster mode)
6. TIS applications (console, assemble, solr) via `./tis restart -force`

Stop sequence in `stop.yml` is the reverse to ensure clean shutdown.

### Ansible Role Organization

Roles follow standard Ansible structure (`defaults/`, `tasks/`, `handlers/`, `templates/`, `vars/`):

**Infrastructure Roles:**
- `init-os`: System initialization, required packages
- `jdk`: Java 11 installation
- `zookeeper`: Zookeeper 3.4.14 setup
- `hadoop`: HDFS and YARN configuration
- `spark`, `hive`, `flink`: Big data processing engines

**Application Roles:**
- `console`: TIS console (tjs) with web UI
- `assemble`: TIS assemble service
- `solr-core`, `solrhome`: Search infrastructure
- `index-builder`: Index building on YARN
- `ng-tis`: Angular frontend compilation using Node.js

**Build Roles:**
- `compile`: Maven compilation orchestration, pulls from Git
- `download`: Downloads artifacts from OSS
- `deploy-tar`: Artifact deployment to remote repository
- `tis-boot`, `tis-incr`: Docker image building
- `update-center`: Plugin metadata generation

### Key Design Patterns

**Symbolic Link Management:**
- Installation uses `/opt` as base, but creates symlinks if a larger partition exists
- HDFS/YARN scripts use `dirname "${BASH_SOURCE-$0}"` which resolves physical paths
- **Important**: All nodes must have their largest partition mounted at the same path to avoid startup failures

**Maven Profiles:**
- Different Hadoop distributions require different profiles: `-Pcdh`, `-Paliyun-emr`
- Plugins compiled with multiple classifiers for compatibility
- `maven_extra_params` in playbooks control build variants

**Tag-based Execution:**
- Use `--tags` to run specific deployment phases (e.g., `--tags pkg,ng-tis`)
- Use `--skip-tags=deploy` to compile without deploying to artifact repository
- Common tags: `initos`, `zk`, `hadoop`, `spark`, `pkg`, `pkg-plugin`, `ng-tis`, `tjs`, `assemble`, `indexbuilder`, `solr`

**Conditional Installation:**
- Roles check for artifact existence before executing: `when: release_files.stdout.find('xxx.tar.gz') != -1`
- Feature flags in vars.yml control optional component installation

## Important Notes

### Pre-deployment Requirements

1. Configure `vars.yml` with correct version, memory settings, and installation flags
2. Configure `inventory/hosts` with all required host groups and IP addresses
3. Ensure all target machines have the same largest partition mount point (check with: `lsblk | awk '{if ($7) print $4 " " $7}' | sort -h | tail -n 1 | awk '{print $2}'`)
4. Set up SSH key-based authentication from control node to all target hosts
5. Configure database connection for TIS console (`tisconsole_db_url`, `tisconsole_db_username`, `tisconsole_db_password`)

### Database Initialization

After first installation:
1. Import SQL schema from `tis_console_mysql.sql` into MySQL database
2. Access TIS web UI at `http://tis-console-host:8080`
3. Configure: `zkaddress` (e.g., `zk1:2181,zk2:2181,zk3:2181/tis/cloud`) and `tis_hdfs_root_dir` (e.g., `/xxx/data`)
4. Restart Solr services
5. Set HDFS permissions: `su - hadoop && hdfs dfs -chmod -R 777 /`

### Current Version

The repository is configured for TIS version **4.3.0** with:
- Hadoop 3.2.4
- Spark 3.3.2
- Hive 4.0.0
- Flink 1.20.1 (custom TIS fork)
- Zookeeper 3.4.14
- Java 11

### Modifying Playbooks

When editing playbooks or roles, remember:
- `become: yes` and `become_user` control privilege escalation
- Service users: `hadoop:hadoop`, `zookeeper:zookeeper`, `tis` for TIS apps
- Use `delegate_to: localhost` for control node operations
- `ignore_errors: yes` is common for idempotent restart operations