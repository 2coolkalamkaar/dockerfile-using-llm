#!/bin/bash

# Define model and maximum iterations
MODEL="docker-generator"
MAX_RETRIES=3
CURRENT_RETRY=0

# Check if application name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 \"<technology stack>\""
    echo "Example: $0 \"python flask\""
    exit 1
fi

APP_STACK=$1
DOCKERFILE="Dockerfile"
TEMP_RESPONSE="docker_output.tmp"

# Initial prompt
PROMPT="Generate a Dockerfile for $APP_STACK."

echo "🚀 Generating initial Dockerfile for: $APP_STACK"

while [ $CURRENT_RETRY -lt $MAX_RETRIES ]; do
    echo "--------------------------------------------------------"
    echo "Attempt $((CURRENT_RETRY + 1)) of $MAX_RETRIES..."
    
    # Run Ollama and save output
    ollama run $MODEL "$PROMPT" > $TEMP_RESPONSE
    
    # Extract only the code block if it exists, otherwise assume the whole response is the Dockerfile
    # The system prompt says "DO NOT include explanations or markdown formatting" but just in case
    # we filter out markdown block markers
    grep -v '^```' $TEMP_RESPONSE > $DOCKERFILE
    
    # Run Hadolint to check for issues
    echo "🔍 Running Hadolint..."
    HADOLINT_OUTPUT=$(hadolint $DOCKERFILE 2>&1)
    HADOLINT_EXIT_CODE=$?

    if [ $HADOLINT_EXIT_CODE -eq 0 ]; then
        echo "✅ Success! Dockerfile passed all Hadolint checks."
        cat $DOCKERFILE
        echo "--------------------------------------------------------"
        echo "🎉 The final Dockerfile is saved as '$DOCKERFILE'."
        rm $TEMP_RESPONSE
        exit 0
    else
        echo "⚠️ Hadolint detected issues:"
        echo "$HADOLINT_OUTPUT"
        
        # Prepare the feedback prompt for the next iteration
        PROMPT="You generated this Dockerfile for $APP_STACK:
$(cat $DOCKERFILE)

However, it failed linting checks. Fix the following Hadolint errors and return ONLY the corrected Dockerfile:
$HADOLINT_OUTPUT"

        CURRENT_RETRY=$((CURRENT_RETRY + 1))
        
        if [ $CURRENT_RETRY -lt $MAX_RETRIES ]; then
            echo "🔄 Sending feedback to AI for correction..."
        fi
    fi
done

echo "--------------------------------------------------------"
echo "❌ Failed to generate a fully compliant Dockerfile after $MAX_RETRIES attempts."
echo "Here is the last generated output (with errors):"
cat $DOCKERFILE
rm $TEMP_RESPONSE
echo "Please review manually."
exit 1
