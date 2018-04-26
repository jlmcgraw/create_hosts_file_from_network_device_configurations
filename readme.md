This is a collection of scripts to pull information from the configuration files of various network devices (eg. Cisco IOS/Nexus/ASA and Riverbed Steelheads) and use it to create a hosts file with all layer 3 interfaces in it

It will also indicate interfaces which pass through a Steelhead inpath interface by matching up assigned subnets.

Adding this information to DNS can make traceroutes much easier to understand

For example:

    $ tracepath 10.10.10.25
        1:  MY_SWITCH-Vlan30                                                  2.983ms 
        2:  MY_ROUTER-GigabitEthernet0-1-MY_STEELHEAD-inpath0_0               4.072ms 
        3:  10.20.30.15                                                      15.265ms 
        4:  THEIR_ROUTER-Serial0-1                                           11.894ms 
        5:  THEIR_SWITCH-GigabitEthernet1-0-1-THEIR_STEELHEAD-inpath0_1      13.772ms 
        6:  10.10.10.25                                                      22.758ms 


Getting started
---------------
Execute the setup script to install needed modules
	./setup.sh

Run the shell scripts in their numerical order:

	./1_make_destination_directories.sh
		To create any necessary directories

	./2_clear_input_files.sh
		Clear out any old input configuration files

	./3_clear_output_files.sh
		Clear any old output files

Copy all of your configuration files into the "configuration_files" directory

    find . -iname "*.Config" -exec cp {} <full_path_to_configuration_files> \;)

Continue running the scripts on your copied configuration files

	./4_organize_configuration_files.sh
		Moves configuration files around as necessary

	./5_make_inpath_file.sh
		Gather inpath subnets from Steelhead configurations, output to output_5_inpaths.txt

	./6_0_make_base_hosts_file.sh
		Create the base hosts files (output_6_0_hosts.txt / output_6_0_hosts_windows.txt) with defined interfaces

You can now manually add anything to the hosts file that you don't have configs for

	./6_5_find_duplicate_hosts.sh
		find duplicate IPs that may be worth investigating/editing
	
	./7_match_hosts_with_inpaths.sh
		Match up Steelhead inpath subnets with IPs in the output_6_0_hosts.txt file

	./8_combine_inpath_and_hosts_files.sh
		Make a combined hosts file (output_8_0_hosts.txt and output_8_0_hosts_windows.txt)
 
Add the entries in the output_8_0_hosts.txt file to your existing hosts file or DNS system

 	Linux variants
		/etc/hosts

 	Windows
		\windows\system32\drivers\etc

Enjoy your more comprehensible traceroutes!

