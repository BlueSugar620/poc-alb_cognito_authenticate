# poc-alb_cognito_authenticate

## 概要
ALBにCognito認可をつけることを試したコードです。

## ディレクトリ構成
```
.
└── terraform
    ├── main.tf                     # mainファイル
    ├── network.tf                  # VPC, subnetの定義
    ├── lb.tf                       # ALBの定義
    ├── app.tf                      # ECSアプリの定義
    ├── auth.tf                     # Cognitoの定義
    ├── variables.tf                # 変数定義
    ├── outputs.tf                  # 出力定義
    └── container_definitions.json  # アプリの設定ファイル
```

## 使い方

デプロイをする。
```
# 独自ドメインを変数に設定します。
export TF_VAR_domain_name="<独自ドメイン>"

# デプロイします。
terraform init
terraform apply
```

この状態だとアプリケーションにログインできる人がいません。そこで、マネジメントコンソールからユーザーを新しく登録します。

アプリケーションにアクセスすると、認証画面に飛ばされると思います。そこで、先ほど登録したユーザーとしてログインします。初回はパスワードの変更が必要です。
