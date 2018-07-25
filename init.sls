{% for device, config in pillar['filesystems'].items() %}

{% set fstype = config['fstype']|default('ext4') %}
{% set persist = config['persist']|default(true) %}
{% set options = config['options']|default('noatime,nobarrier') %}

# Install filesystem tools
filesystem-tools-{{ device }}:
  pkg.installed:
{% if fstype == 'xfs' %}
    - pkgs: [xfsprogs]
{% elif fstype == 'btrfs' %}
    - pkgs: [btrfs-tools]
{% elif 'ext' in fstype %}
    - pkgs: [e2fsprogs]
{% endif %}

# Format unless it already is formatted
{% if fstype == 'xfs' %}
mkfs.xfs {{ device }}:
  cmd.run:
    - unless: file -s $(readlink -f {{ device }}) |grep -q XFS
    - require:
      - pkg: filesystem-tools-{{ device }}

{% elif fstype == 'btrfs' %}
mkfs.btrfs {{ device }}:
  cmd.run:
    - unless: file -s $(readlink -f {{ device }}) |grep -q BTRFS
    - require:
      - pkg: filesystem-tools-{{ device }}

{% elif 'ext' in fstype %}
mkfs.ext4 {{ device }}:
  cmd.run:
    - unless: file -s $(readlink -f {{ device }}) |grep -q ext4
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
    - mkmnt: true
    - persist: {{ persist }}
    - opts: {{ options }}
{% endif %}
{% endfor %}
