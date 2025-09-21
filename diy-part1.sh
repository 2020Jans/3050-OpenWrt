#!/bin/bash

# 修改默认IP为 192.168.10.1（避免和光猫冲突）
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# 添加自动扩容脚本到系统启动
cat > package/base-files/files/etc/rc.local << EOF
#!/bin/sh -e

# 自动扩容根分区到最大可用空间
if [ -e /dev/sda2 ] && [ "\$(mount | grep '/dev/root' | grep '/dev/sda2')" ]; then
    # 检查是否是第一次启动（通过检查resize标志文件）
    if [ ! -f /etc/resize_done ]; then
        echo "Starting automatic root partition resize..."
        
        # 使用 parted 调整分区大小（如果可用）
        if command -v parted >/dev/null 2>&1; then
            parted -s /dev/sda resizepart 2 100%
        fi
        
        # 调整文件系统大小
        resize2fs /dev/sda2
        
        # 创建标志文件，避免下次启动再次执行
        touch /etc/resize_done
        echo "Root partition resize completed successfully!"
    fi
fi

exit 0
EOF

# 确保启动脚本有执行权限
chmod +x package/base-files/files/etc/rc.local

# 添加磁盘管理相关工具到镜像中
echo "CONFIG_PACKAGE_parted=y" >> .config
echo "CONFIG_PACKAGE_gdisk=y" >> .config
echo "CONFIG_PACKAGE_lsblk=y" >> .config

# 更新并安装所有软件源
./scripts/feeds update -a
./scripts/feeds install -a
