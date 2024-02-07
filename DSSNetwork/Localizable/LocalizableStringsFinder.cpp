#include<stdio.h>
#include<stdlib.h>
#include<dirent.h>
#include<string.h>

#define max(x,y) ((x) >= (y)) ? (x) : (y)
#define min(x,y) ((x) <= (y)) ? (x) : (y)
#define Language struct DSSLanguage

bool printDirectoryInfo(char*, int);
char* tabs(int);
bool isType(char[], char[]);
bool filterFilesWithExtension(char[], char[]);
void searchForLocalizableStrings(char []);
void getLocalizableStringsInLine(char []);
void substring(char *, char [], int, int);
void insertLocalizedString(char string[], int numberOfLanguages, Language languages[]);

struct DSSLanguage {
    char name[1024];
    char path[1024];
};

int main() {
    char rootDir[] = "../../";
    char swiftExtension[] = "swift";
    // printDirectoryInfo(rootDir, 0);

    filterFilesWithExtension(swiftExtension, rootDir);

    return 0;
}

bool filterFilesWithExtension(char extension[], char dirName[]) {
    struct dirent *content;
    char localElement[1024];

    DIR *directory = opendir(dirName);
    if (directory == NULL) { return false; }

    while ((content = readdir(directory))) {
        strcpy(localElement, dirName);
        strcat(localElement, content->d_name);
        switch(content->d_type) {
            case 4:
            if (strcmp(content->d_name, ".") * strcmp(content->d_name, "..") * strcmp(content->d_name, "...") != 0) {
                strcat(localElement, "/");
                filterFilesWithExtension(extension, localElement);
            }
            break;
            case 8:
            if (isType(content->d_name, extension)) searchForLocalizableStrings(localElement);
            break;
        }
    }

    closedir(directory);
    return true;
}

bool printDirectoryInfo(char dirName[], int numberOfTabs) {
    struct dirent *content;
    char localElement[1024];
    char *stringTabs = tabs(numberOfTabs);
    printf("%sOpening: %s\n", stringTabs, dirName);

    DIR *directory = opendir(dirName);
    if (directory == NULL) {
        printf("Failed to open directory: %s\n", dirName);
        return false;
    }

    while ((content = readdir(directory))) {
        switch(content->d_type) {
            case 4:
            if (strcmp(content->d_name, ".") * strcmp(content->d_name, "..") * strcmp(content->d_name, "...") != 0) {
                strcpy(localElement, dirName);
                strcat(localElement, content->d_name);
                strcat(localElement, "/");
                printDirectoryInfo(localElement, numberOfTabs + 1);
            }
            break;
            case 8:
            printf("%s%s\n", stringTabs, content->d_name);
            break;
        }
    }

    free(stringTabs);
    closedir(directory);
    return true;
}

char *tabs(int numberOfTabs) {
    char *tabPointer = (char *) malloc(numberOfTabs * 3 * sizeof(char));

    for(int i = 0; i < numberOfTabs * 3; i++) {
        *(tabPointer + i) = '-';
    }
    return tabPointer;
}

bool isType(char fileName[], char extension[]) {
    int extensionLength = strlen(extension);
    int fileNameLength = strlen(fileName);
    char dotExtension[extensionLength + 1];
    dotExtension[0] = '.';
    dotExtension[1] = '\0';
    strcat(dotExtension, extension);
    char *fileExtension = (char*) malloc((extensionLength + 1) * sizeof(char));

    for (int i = 0; i <= extensionLength; i++) {
        *(fileExtension + i) = fileName[fileNameLength - extensionLength - 1 + i];
        *(fileExtension + i + 1) = '\0';
    }

    if (strcmp(fileExtension, dotExtension) == 0) {
        free(fileExtension);
        return true;
    }
    free(fileExtension);
    return false;
}

void searchForLocalizableStrings(char fileName[]) {
    FILE *file = fopen(fileName, "r");
    int maximumLineLength = 2048;
    char *lineBuffer = (char *) malloc(maximumLineLength * sizeof(char));
    if (lineBuffer == NULL) {
        printf("Failed to alocate buffer to read the file...");
        return;
    }
    printf("Looking for localizable strings in: %s\n", fileName);
    if (file == NULL) {
        printf("Failed to open %s\n", fileName);
        return;
    }
    
    while(fgets(lineBuffer, maximumLineLength, file)) getLocalizableStringsInLine(lineBuffer);
    
    
    printf("\n");
    fclose(file);
    free(lineBuffer);
}

void getLocalizableStringsInLine(char line[]) {
    Language languages[2];
    strcpy(languages[0].path, "./en.lproj/");
    strcpy(languages[1].path, "./es-419.lproj/");

    strcpy(languages[0].name, "Localizable.strings");
    strcpy(languages[1].name, "Localizable.strings");

    int maxNumberOfLocalizableStrings;
    int lineLength = strlen(line);
    char prefixKeyword[] = "\"LOCAL:";
    char sufixKeyword[] = "\".localized";
    int prefixKeywordLength = strlen(prefixKeyword);
    int sufixKeywordLength = strlen(sufixKeyword);
    char *localizableStrings[maxNumberOfLocalizableStrings];
    char *substringBuffer = (char*) malloc(strlen(line) * sizeof(char));

    if (substringBuffer == NULL) { return; }
    for (int i = 0; i < lineLength - sufixKeywordLength; i++) {
        substring(substringBuffer, line, i, prefixKeywordLength);
        if (strcmp(substringBuffer, prefixKeyword) == 0) {
            for (int j = i + 1; j < lineLength - sufixKeywordLength; j++) {
                substring(substringBuffer, line, j, sufixKeywordLength);
                if (strcmp(substringBuffer, sufixKeyword) == 0) {
                    substring(substringBuffer, line, i, j - i + 1);
                    insertLocalizedString(substringBuffer, 2, languages);
                    i = j;
                    break;
                }
            }
        }
    }
}

void insertLocalizedString(char string[], int numberOfLanguages, Language languages[]) {
    FILE *files[numberOfLanguages];
    char *filePaths[numberOfLanguages];
    int maximumLineLength = 2048;
    char *lineBuffer = (char *) malloc(maximumLineLength * sizeof(char));
    char *lineBuffer2 = (char *) malloc(maximumLineLength * sizeof(char));
    bool flag = false;

    if (lineBuffer == NULL || lineBuffer2 == NULL) {
        printf("Failed to alocate line buffer.");
        return;
    }

    for (int i = 0; i < numberOfLanguages; i++) {
        int filePathLength = strlen(languages[i].path) + strlen(languages[i].name);
        filePaths[i] = (char *) malloc(filePathLength * sizeof(char)) ;
        strcat(filePaths[i], languages[i].path);
        strcat(filePaths[i], languages[i].name);
    }

    for (int i = 0; i < numberOfLanguages; i++) {
        files[i] = fopen(filePaths[i], "r");
        flag = true;
        if (files[i] == NULL) {
            printf("Failed to open file %s\n", filePaths[i]);
        } else {
            while (fgets(lineBuffer, maximumLineLength, files[i])) {
                substring(lineBuffer2, lineBuffer, 0, strlen(string));
                if (strcmp(lineBuffer2, string) == 0) {
                    printf("Localized string %s already exists in %s file.\n", string, languages[i].name);
                    flag = false;
                }
            }

            fclose(files[i]);
        }

        if (flag) {
            printf("Adding localized string %s in file %s.\n", string, languages[i].name);
            files[i] = fopen(filePaths[i], "a");
            if (files[i] == NULL) {
                files[i] = fopen(filePaths[i], "w");
            }
            if (files[i] == NULL) {
                printf("Failed to open %s\n", filePaths[i]);
                continue;
            }

            fprintf(files[i], "%s = \"<#localized description#>\";\n", string);
            fclose(files[i]);
        }
    }
}

void substring(char *outputString, char string[], int initialIndex, int substringLength) {
    for (int i = 0; i < substringLength; i++) *(outputString + i) = string[initialIndex + i];
    *(outputString + substringLength) = '\0';
}