#!/bin/bash
# https://habrahabr.ru/company/ruvds/blog/327530/
# https://sanych.nnov.ru/content/odnostrochniki_sed
# https://www.linux.org.ru/forum/admin/5710685
# Поставить комментарий sed -i '5s/^/#/' file.conf
# Переменные!
LOCALE_GEN='/etc/locale.gen'
#LINE_LOCALE_GEN_EN='172'
#LINE_LOCALE_GEN_RU='393'
MIRRORLIST='/etc/pacman.d/mirrorlist'
LINE_MIRRORLIST='109,110'
LOCALE_CONF='/etc/locale.conf'
VCONSOLE_CONF='/etc/vconsole.conf'
MKINITCPIO='/etc/mkinitcpio.conf'
SLIM='/etc/slim.conf'
SLIM_THEME='archlinux-simplyblack'
DEFAULT_GRUB='/etc/default/grub'
SDA=''
BOOT=''
ROOT=''
HOME=''
SWAP=''
COMPNAME=''
USER=''
OPTION=''
# Меню, постоянный цикл
PS3='Bash shell archlinux install:'
OPTIONS=("Ru_Options_Set" "Fdisk" "Format_sda" "Mount" "Pacman_Update" "Pacstrap" "Gen_fstab" "Chroot" "Comp_Name" "RU" "GRUB" "Passwd_on_root" "Dhcpcd_Enable" "User_add" "Xorg_and_Video" "Alsa" "DE" "Spectre-Meltdown=OFF" "FAQ" "Quit")
select OPT in "${OPTIONS[@]}"
do
    case $OPT in
        "Ru_Options_Set")
			loadkeys ru && setfont cyr-sun16 && sed -i '/#ru_RU.UTF-8 UTF-8/s/#//' $LOCALE_GEN && locale-gen && export LANG=ru_RU.UTF-8
			#loadkeys ru && setfont cyr-sun16 && sed -i ''$LINE_LOCALE_GEN_RU's/#//' $LOCALE_GEN && locale-gen && export LANG=ru_RU.UTF-8
			echo "Готово!"
		;;
		"Fdisk")
			echo "1) Запустить lsblk"
			echo "2) Разбить ж/д на разделы: fdisk"
			echo -n "Выбор: "
			read OPTION
			
			if [[ "1" = "$OPTION" ]]; then
				lsblk
			fi
			
			if [[ "2" = "$OPTION" ]]; then
				while [[ "$SDA" = "" ]]; do
					echo "Какой диск будем разбивать на разделы?"
					read -p "Введите /dev/sdx: " SDA
				done

				if [[ -n "$SDA" ]]; then
					fdisk $SDA
				fi
			fi
		;;
		"Format_sda")
			while [[ "$BOOT" = "" ]]; do
				echo "Укажите раздел под BOOT?"
				read -p "Введите sdXX: " BOOT
			done

			while [[ "$ROOT" = "" ]]; do
				echo "Укажите раздел под ROOT?"
				read -p "Введите sdXX: " ROOT
			done

			while [[ "$HOME" = "" ]]; do
				echo "Укажите раздел под HOME?"
				read -p "Введите sdXX: " HOME
			done

			while [[ "$SWAP" = "" ]]; do
				echo "Укажите раздел под SWAP?"
				read -p "Введите sdXX: " SWAP
			done

			if [[ -n "$BOOT" && "$ROOT" && "$HOME" && "$SWAP" ]]; then
				mkfs.ext2 -L boot /dev/$BOOT && mkfs.ext4 -L root /dev/$ROOT && mkfs.ext4 -L home /dev/$HOME && mkswap -L swap /dev/$SWAP
				echo "Готово!"
			fi
		;;
		"Mount")
			echo "Монтируем разделы:"
			mount $ROOT /mnt
			mkdir /mnt/{boot,home}
			mount $BOOT /mnt/boot
			mount $HOME /mnt/home
			swapon $SWAP
		;;
		"Pacman_Update")
			sed -i ''$LINE_MIRRORLIST'd' $MIRRORLIST # Удаляем диапазон строк;
			#sed -i '6G' $MIRRORLIST # Добавляем пустую строку к 6 строке;
			sed -i '7i#Russian' $MIRRORLIST # Добавляем к 7 строке текст;
			sed -i '8iServer = http://mirror.yandex.ru/archlinux/$repo/os/$arch' $MIRRORLIST # Добавляем к 8 строке текст;
			pacman -Syy
		;;
		"Pacstrap")
			echo "Устанавливаем базовую систему:"
			pacstrap /mnt base base-devel
		;;
		"Gen_fstab")
			echo "Генерируем fstab:"
			genfstab -U /mnt >> /mnt/etc/fstab
		;;
		"Chroot")
			echo "Перемонтируйте скрипт!"
			arch-chroot /mnt
		;;
		"Comp_Name")
			while [[ "$COMPNAME" = "" ]]; do
				echo "Как будет называться компьютер?"
				read -p "Введите имя компьютера: " COMPNAME
				echo $COMPNAME > /etc/hostname
			done
		;;
		"RU")
			ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && pacman -S ttf-liberation ttf-droid ttf-dejavu
			sed -i '/#en_US.UTF-8 UTF-8/s/#//; /#ru_RU.UTF-8 UTF-8/s/#//' $LOCALE_GEN # Выполняем набор команд;
			#sed -i ''$LINE_LOCALE_GEN_EN's/#//; '$LINE_LOCALE_GEN_RU's/#//' $LOCALE_GEN
			echo -e "LANG=ru_RU.UTF-8\nLC_MESSAGES=ru_RU.UTF-8" >> $LOCALE_CONF # Добавляем каждое значение с новой строки echo -e "123\n321";
			echo -e "KEYMAP=ru\nFONT=cyr-sun16\nLOCALE=ru_RU.UTF-8\nHARDWARECLOCK=UTC\nTIMEZONE=Europe/Moscow\nUSECOLOR=yes" >> $VCONSOLE_CONF
			locale-gen && mkinitcpio -p linux && loadkeys ru && setfont cyr-sun16
			;;
		"GRUB")
			echo "1) BIOS-версия"
			echo "2) EFI-версия"
			echo -n "Выбор: "
			read OPTION

			if [[ "1" = "$OPTION" ]]; then
				pacman -S grub-bios && grub-install /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg
			fi

			if [[ "2" = "$OPTION" ]]; then
				pacman -S grub efibootmgr && grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub && grub-mkconfig -o /boot/grub/grub.cfg && efibootmgr -V
			fi
		;;
		"Passwd_on_root")
			passwd
		;;
		"Dhcpcd_Enable")
			systemctl enable dhcpcd.service
		;;
		"User_add")
			while [[ "$USER" = "" ]]; do
				echo "Имя пользователя?"
				read -p "Введите имя: " USER
				useradd -m -s /bin/bash $USER && passwd $USER
			done
		;;
		"Xorg_and_Video")
			echo "1) Установить X-Server"
			echo "2) Драйвер Nvidia"
			echo "3) Драйвер Intel"
			echo "4) Драйвер Vbox"
			echo -n "Выбор: "
			read OPTION

			if [[ "1" = "$OPTION" ]]; then
				pacman -S xorg-server xorg-xinit
			fi

			if [[ "2" = "$OPTION" ]]; then
				sed -i '7s/()/(nvidia)/' $MKINITCPIO
				pacman -S nvidia nvidia-utils nvidia-settings && nvidia-xconfig && mkinitcpio -p linux
			fi

			if [[ "3" = "$OPTION" ]]; then
				sed -i '7s/()/(i915)/' $MKINITCPIO
				pacman -S xf86-video-intel && mkinitcpio -p linux
			fi

			if [[ "4" = "$OPTION" ]]; then
				pacman -S mesa
			fi
		;;
		"Alsa")
			pacman -S alsa-lib alsa-utils alsa-oss alsa-plugins
		;;
		"DE")
			echo "1) Enlightenment+Slim"
			echo "2) GNome 3"
			echo -n "Выбор: "
			read OPTION

			if [[ "1" = "$OPTION" ]]; then
				pacman -S enlightenment terminology slim archlinux-themes-slim &&
				echo exec enlightenment_start > /home/$USER/.xinitrc
				sed -i '/current_theme/s/default/'$SLIM_THEME'/' $SLIM # Обрабатываем строки по заданному фильтру. Заменяется только первое совпадение /, /4 - замена первых 4, /g - замена всех совпадений.;
				systemctl enable slim.service
			fi

			if [[ "2" = "$OPTION" ]]; then
				echo "Тут пусто"
			fi
		;;
		"Spectre-Meltdown=OFF")
			sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/s/quiet/& pti=off spectre_v2=off/' $DEFAULT_GRUB && mkinitcpio -p linux
			# sed -i 's/quiet/pti=off spectre_v2=off &/' $DEFAULT_GRUB # Добавить перед нужной строкой текс, или по шаблону /шаблон/s/текст &/, или после - /шаблон/s/& текст/;
		;;
		"FAQ")
			echo "После завершения, не забудте выполнить команды:"
			echo "exit"
			echo "umount -R /mnt"
			echo "swapoff /dev/sdxx"
			echo "- и извлечь установочный образ."
			echo "|-----------------------------|"
			echo "Xorg_and_Video"
			echo "Устанавливаем сначала драйвер, а затем иксы."
		;;
        "Quit")
            break
		;;
        *) echo недопустимый вариант;;
    esac
done
