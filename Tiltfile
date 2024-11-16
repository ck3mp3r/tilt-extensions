v1alpha1.extension_repo(
    name="local", url="file://" + os.path.dirname(__file__)
)
v1alpha1.extension(name="vault", repo_name="local", repo_path="vault")
v1alpha1.extension(name="kubevela", repo_name="local", repo_path="kubevela")
v1alpha1.extension(name="kafka", repo_name="local", repo_path="kafka")
v1alpha1.extension(name="cloudnative_pg", repo_name="local", repo_path="cloudnative_pg")

load("ext://vault", "vault_deploy")
load("ext://kubevela", "kubevela_deploy")
load("ext://kafka", "kafka_deploy")
load("ext://cloudnative_pg", "cloudnative_pg_deploy")
load("ext://helm_resource", "helm_resource", "helm_repo")
load("ext://namespace", "namespace_yaml")

update_settings(  # type: ignore
    max_parallel_updates=4,
    k8s_upsert_timeout_secs=240,
    suppress_unused_image_warnings=None,
)

vault_deploy(
    secrets={
        "cubbyhole/myapp": {
            "foo": "bar",
            "bar": "baz",
        }
    },
)

kubevela_deploy()

kafka_deploy()

cloudnative_pg_deploy()

k8s_yaml(namespace_yaml("foo"))
helm_resource(
    "kubevela-local",
    "src/helm/kubevela-local",
    pod_readiness="ignore",
    namespace="foo",
    labels="kubevela-local",
    resource_deps=["vela-core", "cloudnativepg"],
)
