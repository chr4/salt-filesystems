{% for device, config in pillar['filesystems']|dictsort %}

{% set fstype = config['fstype']|default('ext4') %}
{% set persist = config['persist']|default(true) %}
{% set options = config['options']|default('noatime,nobarrier') %}
{% set dump = config['dump']|default('0') %}
{% set pass_num = config['pass_num']|default('2') %}

# Parse UUID/LABEL from device and use /dev/disk/by-uuid for mkfs
{% if device.startswith('UUID=') %}
{% set blkdev = '/dev/disk/by-uuid/' + device.split('=') | last %}
{% elif device.startswith('LABEL=') %}
{% set blkdev = '/dev/disk/by-label/' + device.split('=') | last %}
{% else %}
{% set blkdev = device %}
{% endif %}

# Install filesystem tools
filesystem-tools-{{ device }}:
  pkg.installed:
{% if fstype == 'xfs' %}
    - pkgs: [xfsprogs]
{% elif fstype == 'btrfs' %}
    - pkgs: [btrfs-progs]
{% elif 'ext' in fstype %}
    - pkgs: [e2fsprogs]
{% endif %}

# Format unless it already is formatted
{% if fstype == 'xfs' %}
mkfs.xfs {{ blkdev }}:
  cmd.run:
    - unless: file -s $(readlink -f {{ blkdev }}) |grep -q XFS
    - require:
      - pkg: filesystem-tools-{{ device }}

{% elif fstype == 'btrfs' %}
mkfs.btrfs {{ blkdev }}:
  cmd.run:
    - unless: file -s $(readlink -f {{ blkdev }}) |grep -q BTRFS
    - require:
      - pkg: filesystem-tools-{{ device }}

{% elif 'ext' in fstype %}
mkfs.ext4 {{ blkdev }}:
  cmd.run:
    - unless: file -s $(readlink -f {{ blkdev }}) |grep -q ext4
    - require:
      - pkg: filesystem-tools-{{ device }}
{% endif %}

# Mount filesystem if mountpoint is given
{% if config['mountpoint'] is defined %}
mount-{{ device }}:
  mount.mounted:
    - name: {{ config['mountpoint'] }}
    - device: {{ device }}
    - fstype: {{ fstype }}
    - dump: {{ dump }}
    - pass_num: {{ pass_num }}
    - mkmnt: true
    - persist: {{ persist }}
    - opts: {{ options }}
{% endif %}
{% endfor %}
