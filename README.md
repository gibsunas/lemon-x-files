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
npx nx add @nx/react
npx nx add @nx/nest
#npx nx add @nx/jest
npx nx add @nx/webpack
npx nx add @angular-devkit/core
rm -rf .nx
sleep 10


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
  "x-prisma:prisma"
  "x-nestjs:graphql"
  "x-nestjs:microservice"
  "x-nestjs:rest"

)
#npx nx g @nx/plugin:plugin x --linter='eslint' --unitTestRunner='jest' --directory='packages/x'
npx nx g @nx/plugin:plugin x-utils --linter='eslint' --unitTestRunner='jest' --directory='packages/x-utils'

for generator in "${defaultGenerators[@]}"; do
  IFS=':' read -r package name <<< "$generator"


if [ ! -d "packages/$package" ]; then
  echo "$package Directory does not exist. Creating it now..."
  mkdir -p "packages/$package"
  npx nx g @nx/plugin:plugin $package --linter='eslint' --unitTestRunner='jest' --directory="packages/$package"
  sleep 3
  echo "Directory created successfully."
  npx nx g @nx/plugin:generator --name="init" --unitTestRunner='jest' --path="packages/$package/src/generators/init/init";
  sleep 3
fi

if [ ! -d "packages/$package/src/generators/$name" ]; then
  echo "$name Directory does not exist. Creating it now..."

  npx nx g @nx/plugin:generator --name="$name" --unitTestRunner='jest' --path="packages/$package/src/generators/$name/$name";
  echo "Directory created successfully."
  sleep 3
fi


#echo "Generating generator: $name in $package"
#cd "packages/$package"
#npx nx g @nx/plugin:generator --name="$name" --unitTestRunner='jest' --path="packages/$package/src/generators/$name/$name"
#cd ../..

done

cd apps

npx nx g @nx/express:application test --linter eslint --unitTestRunner jest --path='apps/test/'
sleep 3
npx nx g @nx/nest:application --name=empty-dtl --directory=apps/empty-dtl --strict --unitTestRunner=jest --linter=eslint
sleep 3

npx nx g @nx/react:app apps/empty-react-app --e2eTestRunner=cypress --style=css --bundler=webpack --unitTestRunner=jest --routing --linter=eslint --name=empty-react-app
sleep 3
cd ..

cd libs/core

declare -a projects=(
  "api:libs/core/api"
  "user:libs/core/user"
  "view:libs/core/view"
)
#  "utils:libs/core/utils"

#  npx nx g @nx/nest:library --name "x-utils" --simpleName=true --directory="libs/core/utils" --linter=eslint --buildable=true --unitTestRunner=jest --strict --service=true

for project in "${projects[@]}"; do
  IFS=':' read -r name directory <<< "$project"

  echo "Generating library: $name in $directory"
  mkdir -p "$directory" "$directory/src/lib/"
  npx nx g @nx/nest:library --name "$name" --simpleName=true --directory="$directory" --linter=eslint --buildable=true --unitTestRunner=jest --strict --service=true
  npx nx g @nx/nest:resource --crud=true --path="$directory/src/lib/rest/$name-rest" --type=rest --unitTestRunner=jest --dry-run
done
cd ../..
#sleep 20

for project in "${projects[@]}"; do
  IFS=':' read -r name directory <<< "$project"

  echo "Generating crud: $name in $directory"

  npx nx g @nx/nest:resource --crud=true --path="$directory/src/lib/graphql/$name-graphql" --type=graphql-code-first   --unitTestRunner=jest



  npx nx g @nx/nest:resource --crud=true --path="$directory/src/lib/websockets/$name-sockets" --type=ws --unitTestRunner=jest

  npx nx g @nx/nest:resource --crud=true --path="$directory/src/lib/microservice/$name-micro" --type=microservice  --unitTestRunner=jest
  sleep 10
done

#cd ../..


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
  npx nx g @nx/nest:library --name "@lemon/x-$name" --simpleName=true --directory="$directory" --linter=eslint  --buildable=true --unitTestRunner=jest --strict
  sleep 5
  npx nx g @nx/plugin:generator --name="@lemon/x-$name" --unitTestRunner='jest' --path="$directory/src/lib/$name";
#  rsync -avz --update --delete ../lemon-files/tools/ "./tools/"

done
rm -rf tools/*/src/lib/files
rsync -avz ../lemon-files/tools/ ./tools/
rsync -avz ../lemon-files/packages/ ./packages/
rsync -avz ../lemon-files/libs/ ./libs/


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

# TODO: Remove this custom install step here
npm i gherkin-io @cucumber/messages
npx nx run @lemon/x-utils:build
npx nx g github
npx nx g editor
npx nx g @lemon/x-prisma:init --directory="."
npx nx g @lemon/x-uikit:init --directory="."


npx nx g @lemon/x-nestjs:init --directory="."



npx nx g @lemon/x-prisma:init --directory="apps/empty-react-app/"
npx nx g @lemon/x-uikit:init --directory="apps/empty-react-app/"

npx nx g @lemon/x-nestjs:graphql --directory="libs/core/view"
npx nx g @lemon/x-nestjs:graphql --directory="libs/core/user"
npx nx g @lemon/x-nestjs:graphql --directory="libs/core/api"

npx nx g @lemon/x-nestjs:microservice --directory="libs/core/view"
npx nx g @lemon/x-nestjs:microservice --directory="libs/core/user"
npx nx g @lemon/x-nestjs:microservice --directory="libs/core/api"
npm i
jq '.compilerOptions.strictPropertyInitialization = false | .compilerOptions.experimentalDecorators = true | .compilerOptions.noUnusedLocals = false' "tsconfig.base.json" > "tsconfig.temp.json"
mv tsconfig.temp.json tsconfig.base.json
npx nx sync
npx nx run-many --target=build
npx nx release --first-release --dry-run

cd ..


```
