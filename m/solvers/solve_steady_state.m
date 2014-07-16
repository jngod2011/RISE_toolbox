function [ys,retcode]=solve_steady_state(ys0,def,pp,resid_func,...
    optim_opt,arg_zero_solver)

if nargin<6
    arg_zero_solver=1;
end
debug=optim_opt.debug;

nregs=size(ys0,2);
ys=ys0;
retcode=0;
% compute the unique steady state based on the ergodic distribution
%------------------------------------------------------------------
if optim_opt.is_unique
    [TransMat,retcode]=compute_steady_state_transition_matrix(...
        optim_opt.trans_mat_func,...
        ys0(:,1),pp(:,1),def{1},optim_opt.exo_nbr);
    if ~retcode
        [pp_unique,def_unique,retcode]=ergodic_parameters(TransMat.Qinit,def,pp);
    end
end
if ~retcode
    exitflag=1;
    for ireg=1:nregs
        if optim_opt.is_unique
            pp_i=pp_unique;
            def_i=def_unique;
        else
            pp_i=pp(:,ireg);
            def_i=def{ireg};
        end
        if exitflag==1
            if optim_opt.is_linear_model
                % compute the constant
                [resid,PD]=resid_func(ys0(:,ireg),pp_i,def_i);
                if any(resid)
                    ys(:,ireg)=ys0(:,ireg)-pinv(full(PD))*resid; % <-- ys=ys0-PD\const;
                    % The generalized inverse works better when the system is
                    % singular as it is the case when the model is solved with
                    % unit roots. But it might be slower and so I don't know
                    % whether I should put a switch...
                end
                residuals=resid_func(ys(:,ireg),pp_i,def_i);
                exitflag=max(abs(residuals))<=optim_opt.TolFun;
                if ~exitflag
                    if debug
                        disp('using lsqnonlin or fsolve on a linear model')
                    end
                    [ys(:,ireg),exitflag]=steady_state_solver_engine(ys0(:,ireg));
                end
            else
                % Here is why we need good initial values. You cannot, say start at
                % zero for a variable in logs...
                residuals=resid_func(ys0(:,ireg),pp_i,def_i);
                if isnan(residuals)
                    exitflag=-4;
                elseif max(abs(residuals))<=optim_opt.TolFun
                    exitflag=1;
                else
                    [ys(:,ireg),exitflag]=steady_state_solver_engine(ys0(:,ireg));
                end
            end
        end
        if optim_opt.is_unique && nregs>1
            ys=ys(:,ones(1,nregs));
            break
        end
    end
    
    if ~any(isnan(ys(:))) && exitflag==1
        % maybe I should not do the following? especially here?
        ys(abs(ys)<1e-12)=0;
        retcode=0;
    else
        retcode=1; % steady state cannot be solved
    end
end

    function [x1,exitflag]=steady_state_solver_engine(x0)
        if debug
            optim_opt.Display='iter';
        else
            optim_opt.Display='none';
        end
        switch arg_zero_solver
            case 1
                % call to lsqnonlin
                %------------------
                [x1,resnorm,residuals,exitflag]=lsqnonlin(resid_func,x0(:),[],[],optim_opt);  %#ok<*ASGLU>
            case 2
                % call to fsolve
                %------------------
                [x1,fval,exitflag]=fsolve(resid_func,x0(:),optim_opt);
                resnorm=norm(fval);
            otherwise
                error('arg_zero_solver must be either 1 or 2')
        end
        if ismember(exitflag,[1:4,-3]) && ~any(isnan(x1))
            if resnorm > sqrt(optim_opt.TolFun)
                exitflag=inf;
            else
                exitflag=1;
                x1=reshape(x1,size(x0));
            end
        end
    end
end
