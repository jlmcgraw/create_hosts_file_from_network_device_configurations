#!/bin/bash
set -eu               # Always put this in Bourne shell scripts
IFS=$(printf '\n\t')  # Always put this in Bourne shell scripts

# Install necessary software
sudo apt install \
                cpanminus \
                carton \
                perltidy

# Install the libraries in our cpanfile locally
carton install

# Set up hooks to run perltidy on git commit
if [ -d .git ]
    then
  
        cat > .git/hooks/pre-commit << 'EOF'
        
        #!/bin/bash
        find . \
            -maxdepth 1 \
            -type f     \
            \( -iname '*.pl' -or -iname '*.pm' \) \
            -print0 \
                |
                xargs \
                    -0   \
                    -I{} \
                    -P0  \
                    sh -c 'perltidy --perl-best-practices -nst -b {}'
EOF
    fi
    
chmod +x .git/hooks/pre-commit
