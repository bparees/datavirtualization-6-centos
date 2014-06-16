#######################################################################
#                                                                     #
# Creates a base Centos image with JBoss Data Virtualization 6.0.0.GA #
#                                                                     #
#######################################################################

# Use the centos base image
FROM centos

MAINTAINER bparees <bparees@redhat.com>

#################################################################################
# Install Java JDK, SSH and other useful cmdline utilities and updated the system
# install mysql jdbc client
#################################################################################
RUN yum -y install java-1.7.0-openjdk which telnet unzip openssh-server sudo openssh-clients mysql-connector-java tar && \
    yum -y update && \
    yum clean all


# Create jboss user
# and enable sudo group for jboss
RUN useradd -m -d /home/jboss -p jboss jboss && \
    echo '%jboss ALL=(ALL) ALL' >> /etc/sudoers

ENV JAVA_HOME /usr/lib/jvm/jre


############################################
# Install JBoss Data Virtualization 6.0.0.GA
############################################
USER jboss
ENV INSTALLDIR /home/jboss/dv
ENV HOME /home/jboss
RUN mkdir $INSTALLDIR && \
   mkdir $INSTALLDIR/software && \
   mkdir $INSTALLDIR/support && \
   mkdir $INSTALLDIR/jdbc

ADD software/jboss-dv-installer-6.0.0.GA-redhat-4.jar $INSTALLDIR/software/jboss-dv-installer-6.0.0.GA-redhat-4.jar 
ADD support/teiid-security-users.properties $INSTALLDIR/support/teiid-security-users.properties
ADD support/teiid-security-roles.properties $INSTALLDIR/support/teiid-security-roles.properties
ADD support/InstallationScript.xml $INSTALLDIR/support/InstallationScript.xml

RUN java -jar $INSTALLDIR/software/jboss-dv-installer-6.0.0.GA-redhat-4.jar $INSTALLDIR/support/InstallationScript.xml && \
    mv $INSTALLDIR/support/teiid* $INSTALLDIR/jboss-eap-6.1/standalone/configuration && \
    curl -o $INSTALLDIR/jdbc/postgresql-9.3-1101.jdbc41.jar http://jdbc.postgresql.org/download/postgresql-9.3-1101.jdbc41.jar && \
    rm -rf $INSTALLDIR/jboss-eap-6.1/standalone/configuration/standalone_xml_history/current && \
    rm -rf $INSTALLDIR/support && \
    rm -rf $INSTALLDIR/software

# Create default start script - run.sh
USER root
RUN echo "#!/bin/sh" && \
    echo "echo JBoss Data Virtualization Start script" >> $HOME/run.sh && \
    echo "runuser -l jboss -c '$HOME/dv/jboss-eap-6.1/bin/standalone.sh -c standalone.xml -b 0.0.0.0 -bmanagement 0.0.0.0'" >> $HOME/run.sh && \
    chmod +x $HOME/run.sh


EXPOSE 22 3306 5432 8080 9990 27017

ENV STI_SCRIPTS_URL https://raw.githubusercontent.com/bparees/datavirtualization-6-centos/master/.sti/bin

CMD /home/jboss/run.sh
