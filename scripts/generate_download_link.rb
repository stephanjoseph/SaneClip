#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate signed download URLs for SaneClip customers
# Usage: ./scripts/generate_download_link.rb [version] [hours_valid]
#
# Examples:
#   ./scripts/generate_download_link.rb              # Latest version, 48 hours
#   ./scripts/generate_download_link.rb 1.2          # Specific version, 48 hours
#   ./scripts/generate_download_link.rb 1.2 168      # Specific version, 1 week

require 'openssl'

# Configuration
LATEST_VERSION = '1.2'
BASE_URL = 'https://dist.saneclip.com'
DEFAULT_HOURS = 48

# Get secret from keychain (shared with SaneBar)
secret = `security find-generic-password -s sanebar-dist -a signing_secret -w 2>/dev/null`.strip
if secret.empty?
  warn "❌ Signing secret not found in keychain"
  warn "   Run: security add-generic-password -s sanebar-dist -a signing_secret -w 'YOUR_SECRET'"
  exit 1
end

# Parse arguments
version = ARGV[0] || LATEST_VERSION
hours = (ARGV[1] || DEFAULT_HOURS).to_i

file_name = "SaneClip-#{version}.dmg"

# Calculate expiration
expires = (Time.now + (hours * 3600)).to_i

# Generate signature
message = "#{file_name}:#{expires}"
token = OpenSSL::HMAC.hexdigest('SHA256', secret, message)

# Build URL
signed_url = "#{BASE_URL}/#{file_name}?token=#{token}&expires=#{expires}"

# Output
puts
puts "🔗 Signed Download Link (valid for #{hours} hours)"
puts "=" * 70
puts signed_url
puts "=" * 70
puts
puts "Version: SaneClip #{version}"
puts "Expires: #{Time.at(expires).strftime('%Y-%m-%d %H:%M:%S %Z')}"
puts

# Copy to clipboard
system("echo '#{signed_url}' | pbcopy")
puts "📋 Copied to clipboard!"
