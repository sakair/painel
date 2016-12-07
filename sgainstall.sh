#!/bin/bash
# ESSE SCRIPT RODA APENAS EM VERSOES DO UBUNTU DE 14.04 OU MENOS!
# testado em um Ubuntu Server 14.LTS rodando em uma máquina virtualizada pelo VirtualBox v5.0.24
# https://eternallybored.org/misc/wget/

# Antes de tudo, verifica se o usuário está rodando este script como root (créditos ao ):
if [ $UID -ne 0 ]; then #if [$(id -n) != "0"]; também executa
echo
echo "Voce deve executar este script como root! "
exit
else
echo "Usuário devidamente logado como root/sudo... continuando a execução do script."
fi

cd ~;
nomeProj="teste";
echo "Nome a ser usado no projeto: $nomeProj";
nomeDbProj="bancoteste";
echo "Nome a ser usado para o banco de dados: $nomeDbProj";
senhaMysql="123456";
echo "Senha a ser usada neste banco de dados: $senhaMysql";
echo "Instalando dependencias do projeto ${nomeProj}";
export DEBIAN_FRONTEND="noninteractive"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $senhaMysql";
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $senhaMysql";
sudo apt-get install -y --force-yes mysql-server apache2 libapache2-mod-php5 php5-gd php5-mysql curl php5-mcrypt zip unzip;

# pode ser que seja necessária a instalação do 'php5-odbc'

# Depois de instalado o apache, configure o acesso a pasta da seguinte forma:
# E na linha do arquivo deixe da seguinte forma:
# DocumentRoot /var/www;
echo "A escrever 000-default.conf..";
#mkdir ~/.bkp-sgainstall .bkp-sgainstall/etc .bkp-sgainstall/etc/apache2 .bkp-sgainstall/etc/apache2/sites-enabled;
#sudo mv /etc/apache2/sites-enabled/000-default.conf ~/.bkp-sgainstall/etc/apache2/sites-enabled/000-default.conf;
sudo sed -e "s/#ServerName www.example.com/ServerName localhost/" /etc/apache2/sites-enabled/000-default.conf > ~/000-default.conf;
sudo mv ~/000-default.conf /etc/apache2/sites-enabled/000-default.conf
sed -e "s/\/var\/www\/html/\/var\/www/" /etc/apache2/sites-enabled/000-default.conf > ~/000-default.conf;
sudo mv ~/000-default.conf /etc/apache2/sites-enabled/000-default.conf


# Salve o documento em seguida
# No documento disponível no /etc/apache2/apache2.conf 
echo "A escrever apache2.conf...";
#Esse codigo abaixo ele vai restringir a substituição apenas ao bloco que se refere ao diretório '/var/www/'
sed -e '/<Directory \/var\/www\/>/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf > ~/apache2.conf
sudo mv ~/apache2.conf /etc/apache2/apache2.conf;

# E edite o AllowOverride de 'None' para 'All'
# Os últimos dois procedimentos acima irão evitar o problema de Erro 404 ao acessar os arquvos.
sudo service apache2 restart;
# Agora instale o composer, ferramenta que irá instalar o novosga 
echo "A instalar composer..."
curl -sS https://getcomposer.org/installer | php;
sudo mv composer.phar /usr/local/bin/composer;

echo "A criar o projeto... "
# Navegue até a pasta antes de criar o projeto
cd /var/www;

# Crie o projeto de fato
sudo composer create-project novosga/novosga $nomeProj "1.*";
wget --no-check-certificate https://github.com/sakair/painel/raw/master/sga-tjdft.zip

# pode extrair o arquivo acima para o mesmo diretorio /var/www/
unzip sga-tjdft.zip;

# Caso desejar, renomeie a pasta do painel
# sudo mv painel_web_master painel_$nomeProj
sudo rm -rf sga-tjdft.zip $nomeProj && sudo mv sga-tjdft $nomeProj;

# Edite a propriedade da pasta. A pasta passará a ser do 'usuário' "www-data:www-data"
echo "A editar propriedade da pastar /var/www/$nomeProj";
sudo chown www-data:www-data /var/www/$nomeProj;

# Habilita o modo de reescrita do apache
echo "A habilitar modo de reescrita do apache2";
sudo a2enmod rewrite;

# Antes de usar o instalador web, crie um database que será usado para o SGA
echo "Abrindo o mysql..."; 
#Quando pedir a senha, coloque a mesma que você usou na configuração do mysql";
mysql -u root -p$senhaMysql -e "CREATE DATABASE $nomeDbProj; quit;";

cd ~;
# Depois libere o acesso as pastas do /var/www/
sudo chmod 755 /var/www && sudo chmod 777 /var/www/$nomeProj/var/ && sudo chmod 777 /var/www/$nomeProj/config/; 

if [ $(ls /var/www/$nomeProj/var/cache|wc -l) != 0 ]; then # Limpar Cache caso a pasta var possua o arquivo cache
sudo rm -rf /var/www/$nomeProj/var/cache;
echo "Cache Limpo!"
else
echo "Cache já está limpo!"
fi
# por fim, exclua o arquivo "composer.lock" que se encontra na raiz do projeto.
# echo "Tentando remover o arquivo \"composer.lock\"...";
# sudo rm /var/www/$nomeProj/composer.lock;

# No instalador web, o servidor do banco de dados será local, logo o endereço sera o 'localhost' ou '127.0.0.1'
## se for o mysql a porta será o 3306 ou o postgres será a porta default mostrada no momento da instalação

cd /var/www;
# Depois do instalador web, baixar o painel que mostra as senhas:
wget --no-check-certificate https://github.com/sakair/painel/raw/master/painelsga.zip

# pode extrair o arquivo acima para o mesmo diretorio /var/www/
unzip painelsga.zip;

# Caso desejar, renomeie a pasta do painel
# sudo mv painel_web_master painel_$nomeProj
sudo rm painelsga.zip;
sudo rm -rf html/;
echo "...Ok. Instalação finalizada."
sleep 2
clear;
echo "Agora você irá abrir abrir o navegador e digitar as seguintes informações em seus devidos campos:
    - Selecione o \"MYSQL / Maria DB\"
    - Depois disso, avance até chegar na página para preenchimento dos campos e digite o seguinte:
    - Host: localhost
    - Porta: 3306
    - Usuário: root
    - Senha: $senhaMysql
    - Database: $nomeDbProj";
echo "e atualize a página depois de configurar as senhas e pronto."

# Quando vá na configuração, coloque como URL:
# [COM ENV HABILITADO] firefox http://<nome_ou_endereco_do_servidor_do_novosga>/painel_$nomeProj/public
echo "Acesse no seu navegador a seguinte página:
  http://$(hostname -I)/painel_$nomeProj/public";

# No painel web, abra colocando o nome da pasta do painel web:    
sleep 5
echo "Clique na opção flutuante no canto superior direito da tela (configurar): 
  Coloque como endereço: 
    http://$(hostname -I)/$nomeProj/public
  Ou se ele estiver no mesma máquina coloque:
    http://$(hostname -i)/$nomeProj/public'";
    
sleep 5;
echo "Instalado (eu acho...)!"

sleep 2;
clear;
echo "############ OUTRAS INFORMAÇÕES UTEIS ###
Tutorial de como instalar (script 95% baseado nele):
  http://doc.novosga.org/1.0/install.html

Guia de Uso do SGA:
  http://doc.novosga.org/1.0/using.html


########################### BUGS CONHECIDOS ###
Este script foi concebido preparado para burlar algumas situações, mas nem todos os problemas são comuns.
Visite as seguintes páginas caso se depare com os seguintes problemas:

Se a instalação mostrar que não encontra a pasta install: 
http://forum.novosga.org/discussion/608/instalacao-1-5-1-nao-encontra-pasta-install

Se houver falha na sequencia de senhas:
http://forum.novosga.org/discussion/737/falha-na-sequencia-de-senhas

Se houver algum problema relacionada a prioridade dos atendimentos:
http://forum.novosga.org/discussion/426/ordenacao-da-fila-de-prioridade-e-atendimento-normal-esta-invertida
Se o painel ficar empacando no numero 10 durante as chamadas:
http://forum.novosga.org/discussion/744/painel-as-vezes-para-de-chamar

Se as tabelas do banco de dados estiverem com problemas de codificação:
http://forum.novosga.org/discussion/33/resolvendo-postgresql-com-problema-de-codificacao";

