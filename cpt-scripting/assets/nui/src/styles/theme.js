export const theme = {
  colors: {
    dark: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
    shape: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
    primary: (opacity = 1) => `rgba(3, 187, 232, ${opacity})`,
    error: (opacity = 1) => `rgba(255, 51, 0, ${opacity})`,
  },
  fonts: {
    family: {
      primary: "'Montserrat', sans-serif",
    },
  },
};
