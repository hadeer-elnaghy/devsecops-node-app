FROM jenkins/jenkins:lts

USER root

RUN apt-get update && \
    apt-get install -y \
        curl \
        unzip \
        wget \
        gnupg \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && \
    sh /tmp/get-docker.sh && \
    rm /tmp/get-docker.sh

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install Snyk
RUN curl --compressed https://static.snyk.io/cli/latest/snyk-linux \
    -o /usr/local/bin/snyk && \
    chmod +x /usr/local/bin/snyk

# Install Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | gpg --dearmor \
    | tee /usr/share/keyrings/trivy.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
    > /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install -y trivy && \
    rm -rf /var/lib/apt/lists/*


# SonarScanner
RUN curl -L -o /tmp/sonar-scanner.zip \
    https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip && \
    unzip /tmp/sonar-scanner.zip -d /opt/ && \
    mv /opt/sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner && \
    ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar-scanner.zip
USER jenkins
