## Clang Compiler Installer

Clang 4.0.1, 5.0.1 and 6.0.0 + LLVM Gold Plugin Installation for Centmin Mod LEMP stacks on CentOS 7 only

## Clang 4.0.1

```
/opt/sbin/llvm-release_40/bin/clang -v
clang version 4.0.1 (branches/release_40 308665) (llvm/branches/release_40 308664)
Target: x86_64-unknown-linux-gnu
Thread model: posix
InstalledDir: /opt/sbin/llvm-release_40/bin
Found candidate GCC installation: /usr/lib/gcc/x86_64-redhat-linux/4.8.2
Found candidate GCC installation: /usr/lib/gcc/x86_64-redhat-linux/4.8.5
Selected GCC installation: /usr/lib/gcc/x86_64-redhat-linux/4.8.5
Candidate multilib: .;@m64
Candidate multilib: 32;@m32
Selected multilib: .;@m64
```

```
ls -lah /opt/sbin/llvm-release_40/lib/LLVMgold.so
-rwxr-xr-x 1 root root 41M Jul 20 20:50 /opt/sbin/llvm-release_40/lib/LLVMgold.so
```

```
nginx -V
nginx version: nginx/1.13.3
built by clang 4.0.1 (branches/release_40 308665) (llvm/branches/release_40 308664)
built with LibreSSL 2.5.5
TLS SNI support enabled
```
> configure arguments: --with-ld-opt='-lrt -ljemalloc -Wl,-z,relro -Wl,-rpath,/usr/local/lib' --with-cc-opt='-m64 -march=native -DTCP_FASTOPEN=23 -g -O3 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wno-sign-compare -Wno-string-plus-int -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion -Wno-c++11-compat-deprecated-writable-strings -Wno-write-strings -gsplit-dwarf' --sbin-path=/usr/local/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf --with-compat --with-http_stub_status_module --with-http_secure_link_module --with-libatomic --with-http_gzip_static_module --with-http_sub_module --with-http_addition_module --with-http_image_filter_module=dynamic --with-http_geoip_module --with-stream_geoip_module --with-stream_realip_module --with-stream_ssl_preread_module --with-threads --with-stream=dynamic --with-stream_ssl_module --with-http_realip_module --add-dynamic-module=../ngx-fancyindex-0.4.0 --add-module=../ngx_cache_purge-2.3 --add-module=../ngx_devel_kit-0.3.0 --add-module=../set-misc-nginx-module-0.31 --add-module=../echo-nginx-module-0.60 --add-module=../redis2-nginx-module-0.14 --add-module=../ngx_http_redis-0.3.7 --add-module=../memc-nginx-module-0.18 --add-module=../srcache-nginx-module-0.31 --add-module=../headers-more-nginx-module-0.32 --with-pcre=../pcre-8.41 --with-pcre-jit --with-zlib=../zlib-1.2.11 --with-http_ssl_module --with-http_v2_module --with-openssl=../libressl-2.5.5


## Clang 5.0.1

```
/opt/sbin/llvm-release_50/bin/clang -v
clang version 5.0.1 (branches/release_50 323061)
Target: x86_64-unknown-linux-gnu
Thread model: posix
InstalledDir: /opt/sbin/llvm-release_50/bin
Found candidate GCC installation: /opt/rh/devtoolset-4/root/usr/lib/gcc/x86_64-redhat-linux/5.3.1
Found candidate GCC installation: /opt/rh/devtoolset-6/root/usr/lib/gcc/x86_64-redhat-linux/6.3.1
Found candidate GCC installation: /usr/lib/gcc/x86_64-redhat-linux/4.8.2
Found candidate GCC installation: /usr/lib/gcc/x86_64-redhat-linux/4.8.5
Selected GCC installation: /opt/rh/devtoolset-6/root/usr/lib/gcc/x86_64-redhat-linux/6.3.1
Candidate multilib: .;@m64
Candidate multilib: 32;@m32
Selected multilib: .;@m64
```

```
ls -lah /opt/sbin/llvm-release_50/lib/LLVMgold.so
-rwxr-xr-x 1 root root 27M Jan 21 06:32 /opt/sbin/llvm-release_50/lib/LLVMgold.so
```

```
nginx -V
nginx version: nginx/1.13.5
built by clang 5.0.0 (branches/release_50 312822)
built with OpenSSL 1.1.0f  25 May 2017
TLS SNI support enabled
```
> configure arguments: --with-ld-opt='-ljemalloc -Wl,-z,relro -Wl,-rpath,/usr/local/lib' --with-cc-opt='-m64 -march=native -g -O3 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wno-sign-compare -Wno-string-plus-int -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion -Wno-c++11-compat-deprecated-writable-strings -Wno-write-strings -gsplit-dwarf' --sbin-path=/usr/local/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf --with-compat --with-http_stub_status_module --with-http_secure_link_module --with-libatomic --with-http_gzip_static_module --add-dynamic-module=../ngx_brotli --with-http_sub_module --with-http_addition_module --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-stream_geoip_module --with-stream_realip_module --with-stream_ssl_preread_module --with-threads --with-stream=dynamic --with-stream_ssl_module --with-http_realip_module --add-dynamic-module=../ngx-fancyindex-0.4.0 --add-module=../ngx_cache_purge-2.3 --add-module=../ngx_devel_kit-0.3.0 --add-dynamic-module=../set-misc-nginx-module-0.31 --add-dynamic-module=../echo-nginx-module-0.61 --add-dynamic-module=../redis2-nginx-module-0.14 --add-module=../ngx_http_redis-0.3.7 --add-dynamic-module=../memc-nginx-module-0.18 --add-dynamic-module=../srcache-nginx-module-0.31 --add-dynamic-module=../headers-more-nginx-module-0.32 --with-pcre=../pcre-8.41 --with-pcre-jit --with-zlib=../zlib-1.2.11 --with-http_ssl_module --with-http_v2_module --with-openssl=../openssl-1.1.0f --with-openssl-opt='enable-ec_nistp_64_gcc_128'

## Clang 6.0.0

```
/opt/sbin/llvm-release_60/bin/clang -v
clang version 6.0.0 (branches/release_60 323061)
Target: x86_64-unknown-linux-gnu
Thread model: posix
InstalledDir: /opt/sbin/llvm-release_60/bin
Found candidate GCC installation: /opt/rh/devtoolset-4/root/usr/lib/gcc/x86_64-redhat-linux/5.3.1
Found candidate GCC installation: /opt/rh/devtoolset-6/root/usr/lib/gcc/x86_64-redhat-linux/6.3.1
Found candidate GCC installation: /usr/lib/gcc/x86_64-redhat-linux/4.8.2
Found candidate GCC installation: /usr/lib/gcc/x86_64-redhat-linux/4.8.5
Selected GCC installation: /opt/rh/devtoolset-6/root/usr/lib/gcc/x86_64-redhat-linux/6.3.1
Candidate multilib: .;@m64
Candidate multilib: 32;@m32
Selected multilib: .;@m64
```

```
ls -lah /opt/sbin/llvm-release_60/lib/LLVMgold.so
-rwxr-xr-x 1 root root 29M Jan 21 07:22 /opt/sbin/llvm-release_60/lib/LLVMgold.so
```
