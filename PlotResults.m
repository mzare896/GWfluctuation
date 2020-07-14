function PlotResults(targets,outputs,Name)

    errors=round((targets-outputs),2);

    RMSE=round(sqrt(mean(errors(:).^2)),2);
    
    error_mean=round(mean(errors(:)),2);
    error_std=round(std(errors(:)),2);

    subplot(2,2,[1 2]);
    plot(targets,'k','LineWidth',1.5);
    axis tight
    grid on
    hold on;
    plot(outputs,'r:','LineWidth',1.5);
    axis tight
    grid on
    legend('Observed groundwater level','Simulated groundwater level');
    title(Name);

    subplot(2,2,3);
    plot(errors);
    axis tight
    grid on
    legend('Error');
    title(['RMSE = ' num2str(RMSE)]);

    subplot(2,2,4);
    histfit(errors);
    grid on
    title(['Error: mean = ' num2str(error_mean) ', std = ' num2str(error_std)]);

end