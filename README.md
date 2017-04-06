Passo a passo para executar testes de comunicação VM-VM no mesmo host físico e
em hosts diferentes utilizando OvS e DPDK.

Esses scripts se baseiam nas seguintes versões de software:
- DPDK 16.11
- Open vSwitch 2.7
- QEMU >= 2.5

A maioria dos comandos a serem executados devem ser executados com privilégios. Dito
isto, o prefixo `sudo` será omitido no decorrer do tutorial.

### Instalação DPDK 16.11 ###

- Conferir se todas as dependências citadas [aqui](http://dpdk.org/doc/guides/linux_gsg/sys_reqs.html) foram atendidas.

- Instalar make e gcc

- Fazer download do DPDK 16.11 e descompactar

        wget https://fast.dpdk.org/rel/dpdk-16.11.1.tar.xz
        tar -xf dpdk-16.11.1.tar.xz

- Mudar para o diretório do DPDK

- Exportar váriavel de ambiente DPDK_DIR (contendo o diretório que contém os
  arquivos DPDK).
        export DPDK_DIR=$(pwd)

- (Opcional) Editar opção `CONFIG_RTE_BUILD_SHARED_LIB=y` no arquivo `$DPDK_DIR/config/common_base` para utilizar bibliotecas compartilhadas.

- Configurar e instalar o DPDK com o target desejado (nesse caso `x86_64-native-linuxapp-gcc`):

        export DPDK_TARGET=x86_64-native-linuxapp-gcc
        export DPDK_BUILD=$DPDK_DIR/$DPDK_TARGET
        make install T=$DPDK_TARGET DESTDIR=install`

- (Opcional) Se o DPDK tiver sido configurado com bibliotecas compartilhadas,
  é necessário setar uma variável de ambiente que será utilizada durante a
  compilação do OVS:
        export LD_LIBRARY_PATH=$DPDK_DIR/x86_64-native-linuxapp-gcc/lib

!!! - Caso ocorram erros nesta etapa, provavelmente há dependências que precisam
      ser instaladas antes da compilação. Em caso de dúvida, checar o [Intel DPDK
      Getting Started Guide](http://dpdk.org/doc/guides/linux_gsg/)

### Instalação OvS 2.7 ###

- Verificar se todas as dependências listadas [aqui](http://docs.openvswitch.org/en/latest/intro/install/general/#general-build-reqs) foram atendidas.

- Fazer download do OvS 2.7 e descompactar:

        wget http://openvswitch.org/releases/openvswitch-2.7.0.tar.gz
        tar -xf openvswitch-2.7.0.tar.gz

- Mudar para o diretório do OvS.

- Configurar o pacote para usar DPDK e compilar:

        ./configure --with-dpdk=$DPDK_DIR
        make

!!! - Caso ocorram erros, checar o [manual de instalação](http://docs.openvswitch.org/en/latest/intro/install/dpdk/).

### Instalação QEMU ###

Instalar o QEMU pelo gerenciador de pacotes padrão

- Fedora, CentOS, RHEL

        yum install qemu-kvm

- Ubuntu e Debian-based

        apt-get install qemu-kvm

Para suporte a vhost, é necessário QEMU >= 2.2. Caso a versão instalada seja
muito antiga, é possível compilar o QEMU manualmente. A compilação do QEMU é
simples, apenas há várias dependências que devem ser instaladas previamente.
Para instalar as dependências e fazer a compilação, seguir este [tutorial](https://mike632t.wordpress.com/2014/05/03/compiling-qemu/).

### Configurações do ambiente ###

- Primeiro, é necessário reservar 1GB hugepages durante o boot*. No Ubuntu, basta
  adicionar os seguintes parâmetros a `GRUB_CMDLINE_LINUX_DEFAULT` no arquivo
  `/etc/default/grub`:

        iommu=pt intel_iommu=on default_hugepagesz=1G hugepagesz=1G hugepages=8

- Dessa forma, 8 páginas de 1GB serão reservadas durante o boot. Precisamos
  também avisar o grub que modificações foram feitas à linha de boot:

        grub-mkconfig -o /boot/grub/grub.cfg

  Pode-se conferir se as páginas foram reservadas corretamente rodando-se o
  comando:

        hugeadm --pool-list

  do pacote `hugepages`. É necessário reiniciar a máquina para que a reserva das
  páginas seja feita.

OBS: Hugepages de 2MB também podem ser utilizadas, e também podem ser alocadas em
tempo de execução.

### Scripts auxiliares ###

Alguns scripts foram criados para auxiliar nos testes a seguir.

-`export-vars.sh` : Exporta todas as variáveis de ambiente necessárias para a
                   execução dos comandos dos outros scripts. Precisa ser
                   rodado como `source export-vars.sh`

-`configure-DPDK.sh` : Configura a máquina para o uso do DPDK. Monta as
                      hugepages reservadas, carrega os módulos necessários e
                      associa 1 interface de rede ao driver necessário para
                      a execução do DPDK.

-`start-vhost-VV.sh` : Configura o OvS. Cria diretórios necessários para a
                      execução do OvS, bem como cria o banco de dados,
                      inicia o servidor e inicia os processos do OvS com
                      DPDK. Também cria uma bridge "br0" com 3 portas DPDK
                      associadas, uma física (dpdk0) e duas do tipo vhost
                      (vhost-user1 e vhost-user2).

-`start-vhost-VPPV.sh` : Similar ao script `start-vhost-VV.sh`, porém cria
                        apenas 1 porta vhost e cria regras de fluxo para
                        encaminhar pacotes entre a porta física e a porta
                        virtual diretamente (usada no caso de VMs em hosts
                        diferentes).

-`start-vm1.sh` e `start-vm2.sh` : Levantam as VMs com as configurações
                                  necessárias para rodar com OvS e DPDK
                                  vhost.

### Teste de comunicação VM-VM no mesmo host físico ###

- Confira se os caminhos sendo exportados pelo script `export-vars.sh` condizem
  com os caminhos onde o DPDK, OvS e QEMU foram instalados em sua máquina. Após
  isso, rode o script `export-vars.sh` para exportar as variáveis de ambiente
  necessárias para o teste:

            source export-vars.sh

- Agora é necessário configurar a máquina para o uso do DPDK. O script
  `configure-DPDK.sh` é capaz de fazer isso.

            ./configure-DPDK.sh

- Para iniciar os processos do OvS, basta rodar o script `start-vhost-VV.sh`.

            ./start-vhost-VV.sh

- Nesse ponto, o ambiente estará todo configurado para a execução das VMs, então
  podemos iniciá-las:

            ./start-vm1.sh
            ./start-vm2.sh

OBS: certifique-se de que você tem as imagens das máquinas virtuais no diretório
/root/dpdk-ovs-utils/ com o nome Ubuntu-Server-14.04-x64.img e
Ubuntu-Server-14.04-x64-2.img, respectivamente. Caso queira usar uma imagem
diferente ou um diretório diferente, basta alterar os scripts `start-vm1.sh` e/ou
`start-vm2.sh`

- As VMs podem ser acessadas por vnc em :1 e :2. Para fazer o acesso remoto,
  pode-se utilizar o seguinte comando de um terminal externo (PC fora do
  datacenter):

	         ssh <usuario>@<IP-da-maquina-de-testes> -L 5901:localhost:5901 5902:localhost:5902

	Esse comando redirecionará o display das VMs por vnc da máquina remota (uma VM
  rodando vnc na porta 5901	e a outra na porta 5902) para as portas 5901 e 5902,
  respectivamente, do PC local. Tendo feito isso,	basta executar o vncviewer na
  máquina local

	         vncviewer localhost:5901
           vncviewer localhost:5902

- Depois, basta atribuir IPs adequados para as interfaces de rede das VMs e elas
  devem ser capazes de se pingarem.

### Teste de comunicação VM-VM em hosts físicos diferentes ###

- Os passos para executar esse teste são similares ao do teste anterior, mas
  dessa vez, durante a configuração do OvS, deve-ser usar o script
  `start-vhost-VPPV.sh` ao invés de `start-vhost-VV.sh`.

- Com a configuração utilizada nos scripts, não é possível ter acesso à Internet
  nas VMs durante o teste VM-VM em hosts físicos diferentes. Isso se deve ao
  fato de que regras de fluxo foram criadas no switch virtual para que o
  encaminhamento de todos os pacotes seja feito entre a interface DPDK física e
  a virtual diretamente, logo nenhum tráfego pode ser encaminhado para outra
  porta.
