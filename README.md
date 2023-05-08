# EKS Workshop

## Úkoly

1. koukni na `https://app1.workshop.eks.rocks`, `https://app2.workshop.eks.rocks`, `https://app3.workshop.eks.rocks` a zjisti, jestli všechny aplikace fungují (nefungují, ale určitě to zkus a třeba si něčeho všimneš)
2. pokud ne, tak otevři AWS konzoli a pusť se do pátrání

## konzole

1. URL AWS účtu je ___
2. přihlaš se jako `student` s heslem ___
3. pracujeme v regionu `eu-central-1`, tak se tam přepni
4. můžeš klikat kam chceš, ale zajímá tě hlavně:
    - CloudWatch logs
    - CloudWatch logs insights (koukni níž na ukázkovou query)
    - EC2
    - EKS (pohled na resources)

## CloudWatch log groups

Log groupy odpovídající vzoru `/aws/containerinsights/workshop/*` jsou to, co tě asi bude zajímat nejvíce. Hvezdička značí namespace a po rozkliknutí najdeš streamy odpovídající názvu podu a kontejneru.

Zajímavé budou určitě následující namespaces:
- `cluster-autoscaler`
- `event-exporter`

Ale řiď se vlastním úsudkem 😂

V CloudWatch se nehledá moc dobře, ale nástroj Logs Insights tenhle problém docela dobře vyřešil. Dole máš tahák. Zkus to!

## výstup

Nic psát nemusíš, za chvíli se na to společně podíváme a ty už brzy zjistíš, jestli jsi odhadl nedodělané části správně (a nebo jestli jsi našel něco úplně jiného).

## Pomůcky

### Log insights query pro obyčejné logy

```
fields @timestamp, @message, @logStream, @log
| sort @timestamp desc
| limit 200
| display log
```

### Log insights query pro eventy v nějakém namespace

```
fields @timestamp, @message, @logStream, @log
| sort @timestamp desc
| limit 200
| filter log_processed.namespace = "app3"
| display log_processed.msg
```
