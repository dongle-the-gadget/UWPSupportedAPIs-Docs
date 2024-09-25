import {
    baseLayerLuminance,
    StandardLuminance
} from "https://unpkg.com/@fluentui/web-components";

function updateTheme() {
    let matched = window.matchMedia('(prefers-color-scheme: dark)').matches;

    if (matched) {
        baseLayerLuminance.setValueFor(document.documentElement, StandardLuminance.DarkMode);
    }
    else {
        baseLayerLuminance.setValueFor(document.documentElement, StandardLuminance.LightMode);
    }
}

updateTheme();

// MediaQueryList
const darkModePreference = window.matchMedia("(prefers-color-scheme: dark)");

// recommended method for newer browsers: specify event-type as first argument
darkModePreference.addEventListener("change", _ => updateTheme());

// deprecated method for backward compatibility
darkModePreference.addListener(_ => updateTheme());