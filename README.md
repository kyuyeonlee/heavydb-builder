# HeavyDB Build Container

Apply `hacks.diff` to the source code. Use `commit 69d8a78a072181e83e0aacf1c8d0adca7d98f4de (HEAD, tag: v7.1.0, origin/rc/v7.1.0)`

Build docker image

``` bash
docker build -t heavydb-build-env .
```

Run container with interactive shell

``` bash
docker run -it --rm --gpus all\
  -v /home/klee965/src/heavydb:/workspace/heavydb \
  heavydb-build-env \
  bash
```

Build command inside container

``` bash
cd /workspace/heavydb/build

cmake .. \
  -DCMAKE_BUILD_TYPE=debug \
  -DCUDA_CUDA_LIBRARY=/usr/local/cuda/lib64/stubs/libcuda.so \
  -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
  -DArrow_DC_LIBRARY=/usr/local/lib/libarrow.so \
  -DENABLE_GEOS=off \
  -DENABLE_AWS_S3=off \
  -DENABLE_FOLLY=off \
  -DENABLE_TESTS=off

make -j 32
```

Initialize HeavyDB

``` bash
# only for the first time
cd /workspace/heavydb/build
rm -rf data
mkdir data
./bin/initheavy data
```

Run HeavyDB in the background

``` bash
docker run -d --gpus all --name heavydb-dev \
  -v /home/klee965/src/heavydb:/workspace/heavydb \
  heavydb-build-env \
  bash -c "cd /workspace/heavydb/build/ && ./bin/heavydb --data /workspace/heavydb/build/data --port 6274 --http-port 6278 --calcite-port 6279"
```

Run `heavysql` client

``` bash
docker exec -it heavydb-dev /workspace/heavydb/build/bin/heavysql -p {PASSWORD} --db {DATABASE_NAME}
```

Now you can run your build!
