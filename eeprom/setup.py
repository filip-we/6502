from distutils.core import setup

setup(name='Eprom Friend',
        version='1.0',
        description='Program to interract with an EEPROM using an Arduino',
        author='filip-we',
        packages=['serial'],
        entry_points={
                'console_scripts': ['eeprom_friend= eeprom_friend:main']
                }
        )
