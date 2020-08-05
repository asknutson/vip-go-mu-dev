name: vipdev%LANDO_NAME%
recipe: wordpress
env_file:
  - .env
config:
  webroot: wp
  php: '7.3'
  via: nginx
  database: mariadb
  # If you are having trouble getting xdebug to work please see:
  # https://docs.devwithlando.io/tutorials/php.html#toggling-xdebug
  xdebug: true
  config:
    vhosts: ../configs/nginx-wordpress.conf
    php: ../configs/php.ini
proxy:
  appserver_nginx:
    - '%LANDO_NAME%.vipdev.lndo.site'
    - '*.%LANDO_NAME%.vipdev.lndo.site'
services:
  appserver:
    overrides:
      volumes:
        - ../bin:/app/bin
        - ../configs:/app/configs
        - ./mu-plugins:/app/wp/wp-content/mu-plugins
        - ./wp-content/client-mu-plugins:/app/wp/wp-content/client-mu-plugins
        - ./wp-content/images:/app/wp/wp-content/images
        - ./wp-content/languages:/app/wp/wp-content/languages
        - ./wp-content/plugins:/app/wp/wp-content/plugins
        - ./wp-content/private:/var/wp/wp-content/private
        - ./wp-content/themes:/app/wp/wp-content/themes
        - ./wp-content/vip-config:/app/wp/wp-content/vip-config
    run:
      - bash /app/bin/lando/setup.sh
    run_as_root:
      - bash /app/bin/lando/setup-as-root.sh
    build_as_root:
      - apt-get update -y && apt-get install -y subversion libmemcached-dev
      - yes '' | pecl install -f memcache
      - docker-php-ext-enable memcache
    composer:
      phpunit/phpunit: '^6'
  vip-search:
    type: elasticsearch:custom
    overrides:
      image: bitnami/elasticsearch:7.8.0
  phpmyadmin:
    type: phpmyadmin
    hosts:
      - database
  mailhog:
    type: mailhog
    hogfrom:
    - appserver
  memcached:
    type: memcached:1.5.12
tooling:
  test:
    service: appserver
    description: "Run all tests: lando test"
    cmd:
      - cd /app/wp/wp-content/mu-plugins && phpunit
  add-fake-data:
    service: appserver
    description: "Add fake data described in '/configs/fixtures/test_fixtures.yml'. You can also use 'wp fixtures' directly to aim it at other files within lando."
    cmd:
     - wp fixtures load --file=/app/configs/fixtures/test_fixtures.yml
  
  delete-fake-data:
    service: appserver
    description: "Delete all fake data generated by 'wp fixtures'"
    cmd:
     - wp fixtures delete
  
  vip-switch:
    service: appserver
    description: "Swap your wp-content with a client repo or the vip-go-skeleton"
    cmd:
     - bash /app/bin/lando/vip-switch.sh

  setup-multisite:
    service: appserver
    description: "Setup WordPress network to enable multisite mode"
    cmd:
      - bash /app/bin/lando/setup-multisite.sh

  add-site:
    service: appserver
    description: "Add site to a multisite installation"
    cmd:
      - bash /app/bin/lando/add-site.sh
