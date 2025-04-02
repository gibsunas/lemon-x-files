## Guide

### init.sh

```bash
#!/bin/bash
export NX_SKIP_REMOTE_CACHE=true
export NX_GENERATE_QUIET=true

npx -y create-nx-workspace x-root --interactive=false --preset ts --bundler='webpack' --e2eTestRunner='none' --linter='eslint' --formatter='prettier' --workspaces --ci='skip' --useGithub --unitTestRunner='jest'
export ROOT_PATH="x-root"

jq '.name = "@lemon/root" | .license = "UNLICENSED"' "${ROOT_PATH}/package.json" > "${ROOT_PATH}/temp.json"

mv ${ROOT_PATH}/temp.json ${ROOT_PATH}/package.json

export ROOT_PATH="lemon-x-root"
mv x-root/ $ROOT_PATH
cd $ROOT_PATH
mkdir -p apps libs/core tools packages



npx nx add @nx/plugin
npx nx add @nx/js
npx nx add @nx/express
npx nx add @nx/nest
npx nx add @nx/webpack

```

### setup.sh

```bash
#!/bin/bash
cd lemon-x-root/

# Define your projects as an array of objects (name and directory)
declare -a defaultGenerators=(
  "x:application"
  "x:static-application"
  "x:docker"
  "x-uikit:application-shell"
  "x-uikit:ci"
)
#npx nx g @nx/plugin:plugin x --linter='eslint' --unitTestRunner='jest' --directory='packages/x'
#npx nx g @nx/plugin:plugin x-uikit --linter='eslint' --unitTestRunner='jest' --directory='packages/x-uikit'

for generator in "${defaultGenerators[@]}"; do
  IFS=':' read -r package name <<< "$generator"


if [ ! -d "packages/$package" ]; then
  echo "$package Directory does not exist. Creating it now..."
  mkdir -p "packages/$package"
  npx nx g @nx/plugin:plugin $package --linter='eslint' --unitTestRunner='jest' --directory="packages/$package"
  echo "Directory created successfully."
  npx nx g @nx/plugin:generator --name="init" --unitTestRunner='jest' --path="packages/$package/src/generators/init/init";

fi

if [ ! -d "packages/$package/src/generators/$name" ]; then
  echo "$name Directory does not exist. Creating it now..."

  npx nx g @nx/plugin:generator --name="$name" --unitTestRunner='jest' --path="packages/$package/src/generators/$name/$name";
  echo "Directory created successfully."
fi


#echo "Generating generator: $name in $package"
#cd "packages/$package"
#npx nx g @nx/plugin:generator --name="$name" --unitTestRunner='jest' --path="packages/$package/src/generators/$name/$name"
#cd ../..

done

cd apps

npx nx g @nx/express:application test --linter eslint --unitTestRunner jest --path='apps/test/'

npx nx g @nx/nest:application --name=empty-dtl --directory=apps/empty-dtl --strict --unitTestRunner=jest --linter=eslint

cd ..

cd libs/core

declare -a projects=(
  "api:libs/core/api"
  "user:libs/core/user"
  "view:libs/core/view"
)

for project in "${projects[@]}"; do
  IFS=':' read -r name directory <<< "$project"

  echo "Generating library: $name in $directory"
  mkdir -p "$directory" "$directory/src/lib/"
  npx nx g @nx/nest:library --name "$name" --simpleName=true --directory="$directory" --linter=eslint --buildable=true --unitTestRunner=jest --strict --service=true
  npx nx g @nx/nest:resource --crud=true --path="$directory/src/lib/graphql/$name-graphql" --type=graphql-code-first   --unitTestRunner=jest
  npx nx g @nx/nest:resource --crud=true --path="$directory/src/lib/rest/$name-rest" --type=rest --unitTestRunner=jest
  npx nx g @nx/nest:resource --crud=true --path="$directory/src/lib/websockets/$name-sockets" --type=ws --unitTestRunner=jest
  npx nx g @nx/nest:resource --crud=true --path="$directory/src/lib/microservice/$name-micro" --type=microservice  --unitTestRunner=jest

done

cd ../..


#
declare -a tools=(
"github:tools/github"
"editor:tools/editor"
)



for tool in "${tools[@]}"; do
  IFS=':' read -r name directory <<< "$tool"

  echo "Generating tool: $name in $directory"
  mkdir -p "$directory/src/lib"
#
  npx nx g @nx/nest:library --name "$name" --simpleName=true --directory="$directory" --linter=eslint --buildable=true --unitTestRunner=jest --strict
  sleep 5;
  npx nx g @nx/plugin:generator --name="$name" --unitTestRunner='jest' --path="$directory/src/lib/$name";
#  rsync -avz --update --delete ../lemon-files/tools/ "./tools/"
done
rm -rf tools/*/src/lib/files
rsync -avz ../lemon-files/tools/ ./tools/



#declare -a tools=(
#  "github:generators/github"
#)

#
#
#for tool in "${tools[@]}"; do
#  IFS=':' read -r name directory <<< "$tool"
#
#  echo "Copying existing tool: $name in $directory"
#  rsync -avz --update --delete ../lemon-tools/tools/$directory ./tools/$directory
#
#done
npx nx g github
npx nx g editor
cd ..



```
