create_hosts_file_from_network_device_configurations
================
This is a collection of scripts to pull information from the configuration files of various network devices (eg. Cisco IOS/Nexus/ASA and Riverbed Steelheads) and use it to create a hosts file with all layer 3 interfaces in it

It will also indicate interfaces which pass through a Steelhead inpath interface.

Adding this information to DNS can make traceroutes much easier to understand


Getting started
---------------
Run the shell scripts in their numerical order:

	./1_make_destination_directories.sh
		To create any necessary directories

	./2_clear_input_files.sh
		Clear out any old input configuration files

	./3_clear_output_files.sh
		Clear any old output files

Put all of your configuration files into the "configuration_files" directory
  (something like
    find . -iname "*.Config" -exec mv {} <full path to configuration_files> \;)

	./4_organize_configuration_files.sh
		Moves configuration files around as necessary

	./5_make_inpath_file.sh
		Gather inpath subnets from Steelhead configurations, output to inpaths.txt

	./6_0_make_base_hosts_file.sh
		Create the base hosts files (hosts.txt / hosts_windows.txt) with defined interfaces

Manually add anything to the hosts file that you don't have configs for

	./6_5_find_duplicate_hosts.sh
		find duplicate IPs that may be worth investigating/editing
	
	./7_match_hosts_with_inpaths.sh
		Match up Steelhead inpath subnets with IPs in the hosts.txt file

	./8_combine_inpath_and_hosts_files.sh
		Make a combined hosts file (hosts and hosts_windows)
 


