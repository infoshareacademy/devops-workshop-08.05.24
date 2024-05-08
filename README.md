# devops-workshop-08.05.24

## Budujemy Serwer Jenkinsa

![Jenkins - diagram architektury](jenkins.png)

- [devops-workshop-08.05.24](#devops-workshop-080524)
  - [Budujemy Serwer Jenkinsa](#budujemy-serwer-jenkinsa)
  - [CICD - GitHub Actions](#cicd---github-actions)
  - [Wstepna konfiguracja terraform - `provider.tf`](#wstepna-konfiguracja-terraform---providertf)
  - [Siec - `01-vpc.tf`](#siec---01-vpctf)
  - [Uprawnienia - `02-iam.tf`](#uprawnienia---02-iamtf)
  - [Dysk sieciowy EFS - `03-efs.tf`](#dysk-sieciowy-efs---03-efstf)
  - [Konfiguracja szablony dla serwera - `04-ec2.tf`](#konfiguracja-szablony-dla-serwera---04-ec2tf)
  - [Budowanie serwera - `05-build.tf + modules/build`](#budowanie-serwera---05-buildtf--modulesbuild)
  - [Load Balancer - `06-alb.tf`](#load-balancer---06-albtf)
  - [AutoScaling Group - `07-asg.tf`](#autoscaling-group---07-asgtf)
  - [Automatyczne odswieżanie Launch Template - `08-refresh.tf`](#automatyczne-odswieżanie-launch-template---08-refreshtf)


## CICD - GitHub Actions

- Utworzenie bucket'u S3 na pliki stanu terraform - 850480876735-demo-tfstate
- Utworzenie IAM Role dla GitHub Actions
  - dedykowany katalog "cicd"
  - przy pomocy terraform tworzymy:
    - IAM Role - github-actions-demo ktora bedzie miala trust relationship z GitHub i naszym repozytorium
    - OpenID Connect (OIDC) identity provider - ustawienie zaufania dla GitHub'a jako autoryzacji roli.
  - logowanie do aws - `aws sso login --profile dor11`
  - ustawienie defaultowego profilu - `export AWS_DEFAULT_PROFILE=dor11`
  - deployment `cd cicd; terraform init; terraform apply`
- Utworzenie GitHub Actions workflow
  - `cd ..; mkdir -p .github/workflows`
  - `touch .github/workflows/terraform.yml`
  
> Uwaga: Ten kod trzeba zmodyfikowac aby użyć go na innym koncie niż Infoshare Academy

## Wstepna konfiguracja terraform - `provider.tf`

Konfiguracja Terraform statefile i provider'a

> Uwaga: Ten kod trzeba zmodyfikowac aby użyć go na innym koncie niż Infoshare Academy

## Siec - `01-vpc.tf`

Przygotowanie infrastruktury sieciowej dla naszej aplikacji wraz z dostępem do i z Internetu.

Utworzenie reguł firewall (security groups) dla load balancer'a i serwera aplikacyjnego

## Uprawnienia - `02-iam.tf`

Utworzenie dedykowanej IAM Role dla serwera Jenkins z uprawnieniami do logowania przez SSM Session Manager oraz do wysylania logow do CloudWatch Logs

## Dysk sieciowy EFS - `03-efs.tf`

Dysk sieciowy typu NFS na ktorym bedzie przechowywane dane naszej aplikacji. Jest on niezalezny od serwera, podlaczany przy starcie systemy operacyjnego.

## Konfiguracja szablony dla serwera - `04-ec2.tf`

Przygotowanie szablony (Launch Template) który będzie używany przez AutoScaling Group do uruchamiania serwera aplikacyjnego.

## Budowanie serwera - `05-build.tf + modules/build`

Utworzenie moduly ktory stworzy dokument AWS SSM Automation do budowania serwera aplikacyjnego.

Definicje kroków znajduja się w pliku yaml.

Dodatkowo tworzona jest regula w Amazon EventBridge Rules aby serwer budowal sie codziennie o 8:00 UTC

## Load Balancer - `06-alb.tf`

Utworzenie Application Load Balancer wraz z certyfikatem SSL i rejestracja rekordu w domenie.

> Uwaga!: Jest to miejsce, ktore wymaga zmiany jeżeli ma być uruchamiane na innym koncie niz Inforshare Academy. Trzeba zmienic `domain_name` oraz `zone_id` !

## AutoScaling Group - `07-asg.tf`

Utworzenie AutoScaling groupy na bazie przygotowanego wczesnie szbalonu uruchamiania serwera.

Serwer bedzie restartowany automatycznie raz w tygodniu z wykorzystaniem najnowszej wersji Launch Template.

## Automatyczne odswieżanie Launch Template - `08-refresh.tf`

Utworzene funkcji Lambda w pythonie do automatycznego znajdywania najnowszego obrazu serwera aplikacyjnego i uaktualnianie Launch Template.

Dodatkowo tworzona jest regula w Amazon EventBridge Rules aby funkcja Lambda byla wykonywana automatycznie codziennie o 20:00 UTC